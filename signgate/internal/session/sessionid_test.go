package session

import "testing"

func TestDeriveSessionIDDeterministic(t *testing.T) {
	cfg := Config{
		Account:          "0x0000000000000000000000000000000000000001",
		NonceKey:         "12345",
		SessionKey:       "0x0000000000000000000000000000000000000002",
		Token:            "0x00000000000000000000000000000000000000aa",
		AllowedTarget:    "0x00000000000000000000000000000000000000aa",
		AllowedRecipient: "0x0000000000000000000000000000000000000b01",
		AllowedSelector:  "0xa9059cbb",
		MaxPerTransfer:   "100000000",
		MaxTotalSpend:    "500000000",
		ValidAfter:       1,
		ValidUntil:       9999999999,
		AllowBatch:       false,
		PolicyHash:       "0x0000000000000000000000000000000000000000000000000000000000000011",
		ChainID:          84532,
		AdapterAddress:   "0x00000000000000000000000000000000000000c0",
	}
	if err := ValidateV1(cfg); err != nil {
		t.Fatal(err)
	}
	a, err := DeriveSessionID(cfg)
	if err != nil {
		t.Fatal(err)
	}
	b, err := DeriveSessionID(cfg)
	if err != nil {
		t.Fatal(err)
	}
	if a != b {
		t.Fatalf("session id not deterministic")
	}
}
