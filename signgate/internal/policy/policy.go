package policy

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"os"
	"strings"

	"github.com/open-policy-agent/opa/rego"
)

type Input struct {
	AgentID      string `json:"agentId"`
	Account      string `json:"account"`
	ChainID      int64  `json:"chainId"`
	Token        string `json:"token"`
	Recipient    string `json:"recipient"`
	AmountAtomic string `json:"amountAtomic"`
	Execution    struct {
		AllowedTarget   string `json:"allowedTarget,omitempty"`
		Selector        string `json:"selector,omitempty"`
		AllowBatch      *bool  `json:"allowBatch,omitempty"`
		IsBatch         bool   `json:"isBatch,omitempty"`
		SessionValidNow *bool  `json:"sessionValidNow,omitempty"`
	} `json:"execution,omitempty"`
	Resource     struct {
		Method string `json:"method"`
		Domain string `json:"domain"`
		Path   string `json:"path"`
	} `json:"resource"`
	Risk struct {
		RecipientRiskScore int  `json:"recipientRiskScore"`
		SanctionsHit     bool `json:"sanctionsHit"`
	} `json:"risk"`
	Limits struct {
		MaxPerTransfer string `json:"maxPerTransfer"`
		MaxTotalSpend  string `json:"maxTotalSpend"`
	} `json:"limits"`
}

type Result struct {
	Decision    string   `json:"decision"`
	ReasonCodes []string `json:"reasonCodes"`
	PolicyHash  string   `json:"policyHash"`
}

type Engine struct {
	query  rego.PreparedEvalQuery
	policy []byte
}

func New(path string) (*Engine, error) {
	policy, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	r := rego.New(
		rego.Query("data.railguard"),
		rego.Module("railguard.rego", string(policy)),
	)
	pq, err := r.PrepareForEval(context.Background())
	if err != nil {
		return nil, err
	}
	return &Engine{query: pq, policy: policy}, nil
}

func (e *Engine) PolicyHash() string {
	sum := sha256.Sum256(e.policy)
	return "0x" + hex.EncodeToString(sum[:])
}

func (e *Engine) Evaluate(ctx context.Context, in Input) (Result, error) {
	in.AgentID = strings.ToLower(strings.TrimSpace(in.AgentID))
	in.Account = strings.ToLower(strings.TrimSpace(in.Account))
	in.Token = strings.ToLower(strings.TrimSpace(in.Token))
	in.Recipient = strings.ToLower(strings.TrimSpace(in.Recipient))
	in.Resource.Domain = strings.ToLower(strings.TrimSpace(in.Resource.Domain))
	rs, err := e.query.Eval(ctx, rego.EvalInput(in))
	if err != nil {
		return Result{}, err
	}
	if len(rs) == 0 || len(rs[0].Expressions) == 0 {
		return Result{Decision: "BLOCK", ReasonCodes: []string{"POLICY_EMPTY"}}, nil
	}
	b, err := json.Marshal(rs[0].Expressions[0].Value)
	if err != nil {
		return Result{}, err
	}
	var out Result
	if err := json.Unmarshal(b, &out); err != nil {
		return Result{}, err
	}
	out.PolicyHash = e.PolicyHash()
	out.Decision = strings.ToUpper(out.Decision)
	if out.Decision != "ALLOW" && out.Decision != "BLOCK" {
		out.Decision = "BLOCK"
	}
	return out, nil
}
