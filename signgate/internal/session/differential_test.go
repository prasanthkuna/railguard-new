package session

import (
	"testing"

	"github.com/ethereum/go-ethereum/common"
)

// Cross-language fixture: keep in sync with sdk/test/sessionId.test.ts
func TestSessionIdCrossLanguageFixture(t *testing.T) {
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
		ChainID:          84532,
		AdapterAddress:   "0x00000000000000000000000000000000000000c0",
	}
	id, err := DeriveSessionID(cfg)
	if err != nil {
		t.Fatal(err)
	}
	expected := common.HexToHash("0x52a14e7814be7dbf606ee36eb57bef03d9d9e50b72bd13097f14eb123d26b936")
	if id != expected {
		t.Fatalf("sessionId mismatch: got %s want %s", id.Hex(), expected.Hex())
	}
}
