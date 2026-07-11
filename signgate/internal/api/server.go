package api

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/google/uuid"
	"github.com/railguard/signgate/internal/config"
	"github.com/railguard/signgate/internal/eip712"
	"github.com/railguard/signgate/internal/intent"
	"github.com/railguard/signgate/internal/policy"
	"github.com/railguard/signgate/internal/receipt"
	"github.com/railguard/signgate/internal/reservation"
	"github.com/railguard/signgate/internal/session"
	"github.com/railguard/signgate/internal/store"
	"github.com/rs/zerolog"
)

type Server struct {
	log         zerolog.Logger
	cfg         config.Config
	policy      *policy.Engine
	reservation *reservation.Service
	store       store.Repository
	eip712      eip712.Signer
	receipt     receipt.Signer
}

func New(log zerolog.Logger, cfg config.Config, pe *policy.Engine, rs *reservation.Service, st store.Repository) *Server {
	return &Server{
		log:         log,
		cfg:         cfg,
		policy:      pe,
		reservation: rs,
		store:       st,
		eip712: eip712.Signer{
			ChainID:            cfg.ChainID,
			AdapterAddress:     cfg.AdapterAddress,
			RailguardSignerKey: cfg.RailguardSignerKey,
		},
		receipt: receipt.Signer{KeyID: cfg.SignerKeyID, PrivateKey: cfg.ReceiptSignerKey},
	}
}

func (s *Server) Router() http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Recoverer)

	r.Get("/health", s.health)
	r.Post("/v1/intents/evaluate", s.evaluateIntent)
	r.Group(func(r chi.Router) {
		r.Use(requireAPIKey(s.cfg.APIKey))
		r.Post("/v1/sessions/register", s.registerSession)
		r.Post("/v1/reservations/reserve", s.reserveBudget)
		r.Post("/v1/userops/submitted", s.userOpSubmitted)
		r.Post("/v1/userops/finalized", s.userOpFinalized)
		r.Get("/v1/receipts/{decisionId}", s.getReceipt)
		r.Get("/v1/reconciliation/executions/{sessionId}", s.getChainExecution)
	})
	return r
}

func (s *Server) health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (s *Server) evaluateIntent(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	var req intent.EvaluateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}

	intentHash, ci, err := intent.HashFromRequest(req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_ = s.store.SaveIntent(r.Context(), intentHash, req.AgentID, req.Account, req.ChainID, req.Token, req.Recipient, req.AmountAtomic, ci.Domain, ci.Path, req.IdempotencyKey)

	pin := policy.Input{
		AgentID:      req.AgentID,
		Account:      req.Account,
		ChainID:      req.ChainID,
		Token:        req.Token,
		Recipient:    req.Recipient,
		AmountAtomic: req.AmountAtomic,
	}
	pin.Resource.Method = req.Resource.Method
	pin.Resource.Domain = req.Resource.Domain
	pin.Resource.Path = req.Resource.Path
	pin.Limits.MaxPerTransfer = req.Limits.MaxPerTransfer
	pin.Limits.MaxTotalSpend = req.Limits.MaxTotalSpend

	pout, err := s.policy.Evaluate(r.Context(), pin)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	decisionID := "dec_" + uuid.NewString()
	_ = s.store.SaveDecision(r.Context(), decisionID, intentHash, pout.Decision, pout.ReasonCodes, pout.PolicyHash)

	if pout.Decision == "ALLOW" && s.cfg.ReceiptSignerKey != "" {
		signed, err := s.receipt.Sign(receipt.Payload{
			DecisionID:   decisionID,
			Decision:     pout.Decision,
			ReasonCodes:  pout.ReasonCodes,
			AgentID:      req.AgentID,
			IntentHash:   intentHash,
			PolicyHash:   pout.PolicyHash,
			ChainID:      req.ChainID,
			Token:        req.Token,
			Recipient:    req.Recipient,
			AmountAtomic: req.AmountAtomic,
		})
		if err == nil {
			payload, _ := json.Marshal(signed.Payload)
			_ = s.store.SaveReceipt(r.Context(), decisionID, intentHash, "", signed.ReceiptHash, payload, signed.Signature, s.cfg.SignerKeyID)
		}
	}

	s.log.Info().
		Str("decisionId", decisionID).
		Str("intentHash", intentHash).
		Str("decision", pout.Decision).
		Int64("latencyMs", time.Since(start).Milliseconds()).
		Msg("intent evaluated")

	writeJSON(w, http.StatusOK, map[string]any{
		"decision":    pout.Decision,
		"decisionId":  decisionID,
		"intentHash":  intentHash,
		"policyHash":  pout.PolicyHash,
		"reasonCodes": pout.ReasonCodes,
	})
}

type registerSessionReq struct {
	DecisionID       string `json:"decisionId"`
	Account          string `json:"account"`
	AgentID          string `json:"agentId"`
	SessionKey       string `json:"sessionKey"`
	Token            string `json:"token"`
	AllowedTarget    string `json:"allowedTarget"`
	AllowedRecipient string `json:"allowedRecipient"`
	AllowedSelector  string `json:"allowedSelector"`
	NonceKey         string `json:"nonceKey"`
	MaxPerTransfer   string `json:"maxPerTransfer"`
	MaxTotalSpend    string `json:"maxTotalSpend"`
	ValidAfter       int64  `json:"validAfter"`
	ValidUntil       int64  `json:"validUntil"`
	AllowBatch       bool   `json:"allowBatch"`
	PolicyHash       string `json:"policyHash"`
}

func (s *Server) registerSession(w http.ResponseWriter, r *http.Request) {
	if s.cfg.AdapterAddress == "" || s.cfg.RailguardSignerKey == "" {
		http.Error(w, "session cosigning not configured", http.StatusServiceUnavailable)
		return
	}
	var req registerSessionReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}
	if req.DecisionID == "" {
		http.Error(w, "decisionId required", http.StatusBadRequest)
		return
	}
	intentHash, err := s.store.ConsumeAllowDecision(r.Context(), req.DecisionID)
	if err != nil {
		http.Error(w, "decision not consumable", http.StatusForbidden)
		return
	}
	intentAgentID, intentAccount, intentToken, intentRecipient, intentAmount, err := s.store.GetIntentByHash(r.Context(), intentHash)
	if err != nil {
		http.Error(w, "intent not found for decision", http.StatusBadRequest)
		return
	}
	if !strings.EqualFold(req.Account, intentAccount) {
		http.Error(w, "account mismatch with approved intent", http.StatusBadRequest)
		return
	}
	if req.AgentID != "" && req.AgentID != intentAgentID {
		http.Error(w, "agent mismatch with approved intent", http.StatusBadRequest)
		return
	}
	if !strings.EqualFold(req.Token, intentToken) {
		http.Error(w, "token mismatch with approved intent", http.StatusBadRequest)
		return
	}
	if !strings.EqualFold(req.AllowedRecipient, intentRecipient) {
		http.Error(w, "recipient mismatch with approved intent", http.StatusBadRequest)
		return
	}
	if req.MaxPerTransfer != "" && req.MaxPerTransfer != intentAmount {
		http.Error(w, "maxPerTransfer must match approved intent amount", http.StatusBadRequest)
		return
	}
	if req.AllowedTarget == "" {
		req.AllowedTarget = req.Token
	}
	if req.AllowedSelector == "" {
		req.AllowedSelector = "0xa9059cbb"
	}

	if req.PolicyHash == "" {
		req.PolicyHash = s.policy.PolicyHash()
	} else if !strings.EqualFold(req.PolicyHash, s.policy.PolicyHash()) {
		http.Error(w, "policyHash mismatch", http.StatusBadRequest)
		return
	}

	cfg := session.Config{
		Account:          req.Account,
		NonceKey:         req.NonceKey,
		SessionKey:       req.SessionKey,
		Token:            req.Token,
		AllowedTarget:    req.AllowedTarget,
		AllowedRecipient: req.AllowedRecipient,
		AllowedSelector:  req.AllowedSelector,
		MaxPerTransfer:   req.MaxPerTransfer,
		MaxTotalSpend:    req.MaxTotalSpend,
		ValidAfter:       req.ValidAfter,
		ValidUntil:       req.ValidUntil,
		AllowBatch:       req.AllowBatch,
		PolicyHash:       req.PolicyHash,
		ChainID:          s.cfg.ChainID,
		AdapterAddress:   s.cfg.AdapterAddress,
	}
	if err := session.ValidateV1(cfg); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	sessionID, err := session.DeriveSessionID(cfg)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	physical, _ := session.SessionConfigPhysicalHash(cfg)
	digest, sig, err := s.eip712.SignRailguard(cfg)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	_ = s.store.SaveSessionDraft(r.Context(), sessionID.Hex(), map[string]any{
		"account": req.Account, "agentId": req.AgentID, "sessionKey": req.SessionKey,
		"token": req.Token, "allowedTarget": req.AllowedTarget, "allowedRecipient": req.AllowedRecipient,
		"allowedSelector": req.AllowedSelector, "nonceKey": req.NonceKey, "maxPerTransfer": req.MaxPerTransfer,
		"maxTotalSpend": req.MaxTotalSpend, "validAfter": req.ValidAfter, "validUntil": req.ValidUntil,
		"allowBatch": req.AllowBatch, "policyHash": req.PolicyHash,
	}, "SESSION_DRAFTED")

	writeJSON(w, http.StatusOK, map[string]string{
		"sessionId":                 sessionID.Hex(),
		"sessionConfigPhysicalHash": physical.Hex(),
		"authorizationDigest":       digest.Hex(),
		"railguardSignature":        "0x" + hexEncode(sig),
	})
}

func hexEncode(b []byte) string {
	const hexdigits = "0123456789abcdef"
	out := make([]byte, len(b)*2)
	for i, v := range b {
		out[i*2] = hexdigits[v>>4]
		out[i*2+1] = hexdigits[v&0x0f]
	}
	return string(out)
}

type reserveReq struct {
	SessionID      string `json:"sessionId"`
	AgentID        string `json:"agentId"`
	IntentHash     string `json:"intentHash"`
	AmountAtomic   string `json:"amountAtomic"`
	IdempotencyKey string `json:"idempotencyKey"`
	MaxTotalSpend  string `json:"maxTotalSpend"`
}

func (s *Server) reserveBudget(w http.ResponseWriter, r *http.Request) {
	var req reserveReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}
	resID, err := s.reservation.Reserve(r.Context(), req.SessionID, req.IdempotencyKey, req.AmountAtomic, req.MaxTotalSpend, 5*time.Minute)
	if err != nil {
		writeJSON(w, http.StatusConflict, map[string]string{"status": "BUDGET_DENIED"})
		return
	}
	_ = s.store.SaveReservation(r.Context(), resID, req.SessionID, req.IntentHash, req.AgentID, req.AmountAtomic, "BUDGET_RESERVED", req.IdempotencyKey)
	writeJSON(w, http.StatusOK, map[string]string{"reservationId": resID, "status": "RESERVED"})
}

type submittedReq struct {
	ReservationID string `json:"reservationId"`
	UserOpHash    string `json:"userOpHash"`
	Bundler       string `json:"bundler"`
}

func (s *Server) userOpSubmitted(w http.ResponseWriter, r *http.Request) {
	var req submittedReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}
	_ = s.store.UpdateReservationStatus(r.Context(), req.ReservationID, "USEROP_SUBMITTED")
	_ = s.store.SaveUserOp(r.Context(), req.UserOpHash, req.ReservationID, "", "USEROP_SUBMITTED", req.Bundler)
	writeJSON(w, http.StatusOK, map[string]string{"status": "USEROP_SUBMITTED"})
}

type finalizedReq struct {
	UserOpHash  string `json:"userOpHash"`
	TxHash      string `json:"txHash"`
	BlockNumber int64  `json:"blockNumber"`
	Status      string `json:"status"`
}

func (s *Server) userOpFinalized(w http.ResponseWriter, r *http.Request) {
	var req finalizedReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}
	status := strings.ToUpper(strings.TrimSpace(req.Status))
	switch status {
	case "USEROP_FINALIZED", "USEROP_REVERTED":
	default:
		http.Error(w, "invalid status", http.StatusBadRequest)
		return
	}
	if err := s.store.FinalizeUserOp(r.Context(), req.UserOpHash, req.TxHash, req.BlockNumber, status); err != nil {
		http.Error(w, "userop not found", http.StatusNotFound)
		return
	}
	reservationID, err := s.store.GetReservationIDByUserOp(r.Context(), req.UserOpHash)
	if err == nil {
		switch status {
		case "USEROP_FINALIZED":
			_ = s.reservation.CommitReservation(r.Context(), reservationID)
			_ = s.store.UpdateReservationStatus(r.Context(), reservationID, "BUDGET_COMMITTED")
		case "USEROP_REVERTED":
			_ = s.reservation.ReleaseReservation(r.Context(), reservationID)
			_ = s.store.UpdateReservationStatus(r.Context(), reservationID, "BUDGET_RELEASED")
		}
	}
	outStatus := "BUDGET_COMMITTED"
	if status == "USEROP_REVERTED" {
		outStatus = "BUDGET_RELEASED"
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": outStatus})
}

func (s *Server) getReceipt(w http.ResponseWriter, r *http.Request) {
	decisionID := chi.URLParam(r, "decisionId")
	decision, receiptHash, signature, payload, err := s.store.GetReceipt(r.Context(), decisionID)
	if err != nil {
		http.Error(w, "not found", http.StatusNotFound)
		return
	}
	var receiptPayload any
	if len(payload) > 0 {
		_ = json.Unmarshal(payload, &receiptPayload)
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"decisionId":  decisionID,
		"decision":    decision,
		"receiptHash": receiptHash,
		"signature":   signature,
		"payload":     receiptPayload,
	})
}

func (s *Server) getChainExecution(w http.ResponseWriter, r *http.Request) {
	sessionID := chi.URLParam(r, "sessionId")
	exec, err := s.store.GetChainExecutionBySessionID(r.Context(), sessionID)
	if err != nil {
		http.Error(w, "not found", http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"account":         exec.Account,
		"sessionId":       exec.SessionID,
		"nonceKey":        exec.NonceKey,
		"frameSpend":      exec.FrameSpend,
		"totalSpendAfter": exec.TotalSpendAfter,
		"blockNumber":     exec.BlockNumber,
		"txHash":          exec.TxHash,
		"logIndex":        exec.LogIndex,
	})
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func ListenAndServe(ctx context.Context, log zerolog.Logger, cfg config.Config, srv *Server) error {
	httpServer := &http.Server{
		Addr:    ":" + cfg.HTTPPort,
		Handler: srv.Router(),
	}
	go func() {
		<-ctx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = httpServer.Shutdown(shutdownCtx)
	}()
	log.Info().Str("port", cfg.HTTPPort).Msg("signgate listening")
	return httpServer.ListenAndServe()
}
