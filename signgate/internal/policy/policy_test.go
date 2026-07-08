package policy

import (
	"context"
	"testing"
)

func TestEvaluateAllowKnownVendor(t *testing.T) {
	e, err := New("../../../policy/railguard.rego")
	if err != nil {
		t.Fatalf("policy: %v", err)
	}
	out, err := e.Evaluate(context.Background(), Input{
		AgentID:      "agent_support_bot_1",
		Account:      "0x0000000000000000000000000000000000000001",
		ChainID:      84532,
		Token:        "0x00000000000000000000000000000000000000aa",
		Recipient:    "0x0000000000000000000000000000000000000b01",
		AmountAtomic: "100000000",
	})
	if err != nil {
		t.Fatal(err)
	}
	if out.Decision != "ALLOW" {
		t.Fatalf("expected ALLOW got %s", out.Decision)
	}
}

func TestEvaluateBlockSanctioned(t *testing.T) {
	e, err := New("../../../policy/railguard.rego")
	if err != nil {
		t.Fatalf("policy: %v", err)
	}
	in := Input{
		AgentID:      "agent_support_bot_1",
		Account:      "0x1",
		ChainID:      84532,
		Token:        "0xaa",
		Recipient:    "0xdead",
		AmountAtomic: "1",
	}
	in.Risk.SanctionsHit = true
	out, err := e.Evaluate(context.Background(), in)
	if err != nil {
		t.Fatal(err)
	}
	if out.Decision != "BLOCK" {
		t.Fatalf("expected BLOCK got %s", out.Decision)
	}
}
