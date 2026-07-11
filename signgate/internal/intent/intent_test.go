package intent

import "testing"

func TestHashDeterministic(t *testing.T) {
	req := EvaluateRequest{
		AgentID:        "agent_support_bot_1",
		Account:        "0x0000000000000000000000000000000000000001",
		ChainID:        84532,
		Token:          "0x00000000000000000000000000000000000000aa",
		Recipient:      "0x0000000000000000000000000000000000000b01",
		AmountAtomic:   "100000000",
		IdempotencyKey: "idem_1",
	}
	req.Resource.Method = "POST"
	req.Resource.Domain = "api.vendor.com"
	req.Resource.Path = "/v1/report"

	h1, _, err := HashFromRequest(req)
	if err != nil {
		t.Fatal(err)
	}
	h2, _, err := HashFromRequest(req)
	if err != nil {
		t.Fatal(err)
	}
	if h1 != h2 {
		t.Fatalf("intent hash not deterministic")
	}
}

func TestHashIncludesLimits(t *testing.T) {
	base := EvaluateRequest{
		AgentID:      "agent_support_bot_1",
		Account:      "0x0000000000000000000000000000000000000001",
		ChainID:      84532,
		Token:        "0x00000000000000000000000000000000000000aa",
		Recipient:    "0x0000000000000000000000000000000000000b01",
		AmountAtomic: "100000000",
		IdempotencyKey: "idem_1",
	}
	base.Resource.Method = "POST"
	base.Resource.Domain = "api.vendor.com"
	base.Resource.Path = "/v1/report"
	base.Limits.MaxPerTransfer = "100000000"
	base.Limits.MaxTotalSpend = "500000000"

	loose := base
	loose.Limits.MaxTotalSpend = "900000000"

	h1, _, err := HashFromRequest(base)
	if err != nil {
		t.Fatal(err)
	}
	h2, _, err := HashFromRequest(loose)
	if err != nil {
		t.Fatal(err)
	}
	if h1 == h2 {
		t.Fatalf("intent hash must include session limits")
	}
}
