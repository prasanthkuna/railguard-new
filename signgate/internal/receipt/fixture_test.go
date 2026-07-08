package receipt

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"testing"
)

func TestReceiptHashCrossLanguageFixture(t *testing.T) {
	p := Payload{
		ReceiptVersion: "railguard.v1",
		DecisionID:     "dec_cross_lang_fixture",
		Decision:       "ALLOW",
		ReasonCodes:    []string{"WITHIN_LIMITS"},
		AgentID:        "agent_support_bot_1",
		IntentHash:     "0x96734b72ae38ed4166ef08446996462802dd2c7577fe608fdc0c6371a571d150",
		PolicyHash:     "0x1111111111111111111111111111111111111111111111111111111111111111",
		ChainID:        84532,
		Token:          "0x00000000000000000000000000000000000000aa",
		Recipient:      "0x0000000000000000000000000000000000000b01",
		AmountAtomic:   "100000000",
		SignerKeyID:    "railguard-key-v1",
		CreatedAt:      "2026-07-08T00:00:00Z",
	}
	b, err := json.Marshal(p)
	if err != nil {
		t.Fatal(err)
	}
	if string(b) != crossLanguageReceiptJSON {
		t.Fatalf("update crossLanguageReceiptJSON constant:\n%s", string(b))
	}
	got := "0x" + hex.EncodeToString(sha256Sum(b))
	const want = "0x7245e104a747ec015ca02fd107a97e2cefa92f61e3db401e3e1ea3673152c022"
	if got != want {
		t.Fatalf("receipt hash mismatch got %s want %s json=%s", got, want, string(b))
	}
}

func sha256Sum(b []byte) []byte {
	sum := sha256.Sum256(b)
	return sum[:]
}

const crossLanguageReceiptJSON = `{"receiptVersion":"railguard.v1","decisionId":"dec_cross_lang_fixture","decision":"ALLOW","reasonCodes":["WITHIN_LIMITS"],"agentId":"agent_support_bot_1","intentHash":"0x96734b72ae38ed4166ef08446996462802dd2c7577fe608fdc0c6371a571d150","policyHash":"0x1111111111111111111111111111111111111111111111111111111111111111","chainId":84532,"token":"0x00000000000000000000000000000000000000aa","recipient":"0x0000000000000000000000000000000000000b01","amountAtomic":"100000000","allowBatch":false,"signerKeyID":"railguard-key-v1","createdAt":"2026-07-08T00:00:00Z"}`
