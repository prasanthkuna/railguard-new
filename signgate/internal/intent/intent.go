package intent

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/ethereum/go-ethereum/crypto"
)

type Resource struct {
	Method string `json:"method"`
	Domain string `json:"domain"`
	Path   string `json:"path"`
}

type EvaluateRequest struct {
	AgentID        string   `json:"agentId"`
	Account        string   `json:"account"`
	ChainID        int64    `json:"chainId"`
	Token          string   `json:"token"`
	Recipient      string   `json:"recipient"`
	AmountAtomic   string   `json:"amountAtomic"`
	Resource       Resource `json:"resource"`
	IdempotencyKey string   `json:"idempotencyKey"`
	Limits         struct {
		MaxPerTransfer string `json:"maxPerTransfer"`
		MaxTotalSpend  string `json:"maxTotalSpend"`
	} `json:"limits"`
}

type CanonicalIntent struct {
	AgentID      string `json:"agentId"`
	Account      string `json:"account"`
	ChainID      int64  `json:"chainId"`
	Token        string `json:"token"`
	Recipient    string `json:"recipient"`
	AmountAtomic string `json:"amountAtomic"`
	Domain       string `json:"domain"`
	Path         string `json:"path"`
	Method       string `json:"method"`
}

func Canonicalize(req EvaluateRequest) CanonicalIntent {
	return CanonicalIntent{
		AgentID:      strings.ToLower(req.AgentID),
		Account:      strings.ToLower(req.Account),
		ChainID:      req.ChainID,
		Token:        strings.ToLower(req.Token),
		Recipient:    strings.ToLower(req.Recipient),
		AmountAtomic: req.AmountAtomic,
		Domain:       strings.ToLower(req.Resource.Domain),
		Path:         req.Resource.Path,
		Method:       strings.ToUpper(req.Resource.Method),
	}
}

func Hash(ci CanonicalIntent) (string, error) {
	b, err := json.Marshal(ci)
	if err != nil {
		return "", err
	}
	sum := crypto.Keccak256(b)
	return "0x" + fmt.Sprintf("%x", sum), nil
}

func HashFromRequest(req EvaluateRequest) (string, CanonicalIntent, error) {
	ci := Canonicalize(req)
	h, err := Hash(ci)
	if err != nil {
		return "", ci, fmt.Errorf("hash intent: %w", err)
	}
	return h, ci, nil
}
