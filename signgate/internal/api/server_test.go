package api

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/alicebob/miniredis/v2"
	"github.com/railguard/signgate/internal/config"
	"github.com/railguard/signgate/internal/logger"
	"github.com/railguard/signgate/internal/policy"
	"github.com/railguard/signgate/internal/reservation"
	"github.com/railguard/signgate/internal/store"
	"github.com/redis/go-redis/v9"
)

type allowDecisionStore struct {
	store.Noop
	policyHash string
}

func (s allowDecisionStore) GetAllowDecision(context.Context, string) (string, string, store.IntentSnapshot, error) {
	return "0xintent", s.policyHash, store.IntentSnapshot{
		AgentID:        "agent_support_bot_1",
		Account:        "0x0000000000000000000000000000000000000001",
		Token:          "0x00000000000000000000000000000000000000aa",
		Recipient:      "0x0000000000000000000000000000000000000b01",
		AmountAtomic:   "100000000",
		MaxPerTransfer: "100000000",
		MaxTotalSpend:  "500000000",
		AllowBatch:     false,
	}, nil
}

func (allowDecisionStore) AuthorizeSession(context.Context, store.SessionAuthInput, string, map[string]any) error {
	return nil
}

func newTestServer(t *testing.T) (*Server, string) {
	return newTestServerWithStore(t, store.NewNoop())
}

func newTestServerWithStore(t *testing.T, st store.Repository) (*Server, string) {
	t.Helper()
	mr := miniredis.RunT(t)
	pe, err := policy.New("../../../policy/railguard.rego")
	if err != nil {
		t.Fatalf("policy: %v", err)
	}
	cfg := config.Config{
		AppEnv:             "local",
		APIKey:             "test-api-key",
		ChainID:            84532,
		AdapterAddress:     "0x00000000000000000000000000000000000000c0",
		RailguardSignerKey: testRailguardSignerKey,
		SignerKeyID:        "test-signer",
	}
	rs := reservation.NewWithClient(redis.NewClient(&redis.Options{Addr: mr.Addr()}))
	return New(logger.New(), cfg, pe, rs, st), cfg.APIKey
}

// anvil account #1 private key (public test fixture only).
const testRailguardSignerKey = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

func withAPIKey(req *http.Request, apiKey string) {
	req.Header.Set("X-SignGate-API-Key", apiKey)
	req.Header.Set("Content-Type", "application/json")
}

func TestRegisterSessionHappyPath(t *testing.T) {
	mr := miniredis.RunT(t)
	pe, err := policy.New("../../../policy/railguard.rego")
	if err != nil {
		t.Fatalf("policy: %v", err)
	}
	cfg := config.Config{
		AppEnv:             "local",
		APIKey:             "test-api-key",
		ChainID:            84532,
		AdapterAddress:     "0x00000000000000000000000000000000000000c0",
		RailguardSignerKey: testRailguardSignerKey,
		SignerKeyID:        "test-signer",
	}
	rs := reservation.NewWithClient(redis.NewClient(&redis.Options{Addr: mr.Addr()}))
	srv := New(logger.New(), cfg, pe, rs, allowDecisionStore{policyHash: pe.PolicyHash()})
	apiKey := cfg.APIKey
	router := srv.Router()

	body := map[string]any{
		"decisionId": "dec_test_allow",
		"sessionKey": "0x0000000000000000000000000000000000000002",
		"nonceKey":   "12345",
		"validAfter": 1,
		"validUntil": 9999999999,
	}
	b, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/v1/sessions/register", bytes.NewReader(b))
	withAPIKey(req, apiKey)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200 got %d body=%s", rec.Code, rec.Body.String())
	}
	var out map[string]string
	if err := json.Unmarshal(rec.Body.Bytes(), &out); err != nil {
		t.Fatal(err)
	}
	if out["sessionId"] == "" || out["railguardSignature"] == "" {
		t.Fatalf("unexpected response: %+v", out)
	}
}

func TestRegisterSessionPolicyHashMismatch(t *testing.T) {
	srv, apiKey := newTestServer(t)
	router := srv.Router()
	body := map[string]any{
		"decisionId": "dec_missing",
		"sessionKey": "0x0000000000000000000000000000000000000002",
		"nonceKey":   "12345",
		"validAfter": 1,
		"validUntil": 9999999999,
	}
	b, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/v1/sessions/register", bytes.NewReader(b))
	withAPIKey(req, apiKey)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("expected 403 got %d body=%s", rec.Code, rec.Body.String())
	}
}

func TestRegisterSessionMissingAPIKey(t *testing.T) {
	srv, _ := newTestServer(t)
	router := srv.Router()
	req := httptest.NewRequest(http.MethodPost, "/v1/sessions/register", io.NopCloser(bytes.NewReader([]byte(`{}`))))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 got %d", rec.Code)
	}
}

func TestUserOpFinalizedUnknown(t *testing.T) {
	srv, apiKey := newTestServer(t)
	router := srv.Router()
	body := map[string]any{
		"userOpHash":  "0x1111111111111111111111111111111111111111111111111111111111111111",
		"txHash":      "0x2222222222222222222222222222222222222222222222222222222222222222",
		"blockNumber": 1,
		"status":      "USEROP_FINALIZED",
	}
	b, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/v1/userops/finalized", bytes.NewReader(b))
	withAPIKey(req, apiKey)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404 got %d body=%s", rec.Code, rec.Body.String())
	}
}

func TestGetReceiptRequiresAPIKey(t *testing.T) {
	srv, apiKey := newTestServer(t)
	router := srv.Router()

	req := httptest.NewRequest(http.MethodGet, "/v1/receipts/dec_missing", nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 got %d", rec.Code)
	}

	req = httptest.NewRequest(http.MethodGet, "/v1/receipts/dec_missing", nil)
	withAPIKey(req, apiKey)
	rec = httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected 404 got %d", rec.Code)
	}
}
