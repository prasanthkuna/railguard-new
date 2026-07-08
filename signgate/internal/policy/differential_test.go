package policy

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

type physicalVector struct {
	Name        string `json:"name"`
	HookAllows  bool   `json:"hookAllows"`
	PolicyInput Input  `json:"policyInput"`
}

// OPA may be stricter than the on-chain hook; it must never be looser than the physical floor.
func TestPhysicalVectorsPolicyNotLooserThanHook(t *testing.T) {
	path := filepath.Join("..", "..", "..", "fixtures", "physical_vectors.json")
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read fixtures: %v", err)
	}
	var vectors []physicalVector
	if err := json.Unmarshal(raw, &vectors); err != nil {
		t.Fatal(err)
	}
	engine, err := New(filepath.Join("..", "..", "..", "policy", "railguard.rego"))
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	for _, v := range vectors {
		out, err := engine.Evaluate(ctx, v.PolicyInput)
		if err != nil {
			t.Fatalf("%s: %v", v.Name, err)
		}
		if !v.HookAllows && out.Decision == "ALLOW" {
			t.Fatalf("%s: OPA ALLOW but hook would reject (policy looser than physical floor)", v.Name)
		}
	}
}
