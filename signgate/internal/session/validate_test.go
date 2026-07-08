package session

import "testing"

func TestValidateV1RejectsInvalidPolicyHash(t *testing.T) {
	cfg := Config{
		Account:          "0x1",
		NonceKey:         "1",
		SessionKey:       "0x2",
		Token:            "0xaa",
		AllowedRecipient: "0xb01",
		MaxPerTransfer:   "100",
		MaxTotalSpend:    "500",
		ValidAfter:       1,
		ValidUntil:       999,
		PolicyHash:       "0xdead",
	}
	if err := ValidateV1(cfg); err == nil {
		t.Fatal("expected policyHash validation error")
	}
}
