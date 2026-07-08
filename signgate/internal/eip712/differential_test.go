package eip712

import (
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/railguard/signgate/internal/session"
)

const eip712VectorAdapter = "0x2e234DAe75C793f67A35089C9d99245E1C58470b"
const eip712VectorDigest = "0xe500012fc5fb6423b2c95575f276c554190b953c054f9183465e2783d5bfa7a1"

// Cross-language fixture: keep in sync with sdk/test/eip712Vectors.test.ts and contracts/test/Eip712Vector.t.sol
func TestEIP712CrossLanguageFixture(t *testing.T) {
	cfg := session.Config{
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
		AdapterAddress:   eip712VectorAdapter,
	}

	signer := Signer{ChainID: cfg.ChainID, AdapterAddress: cfg.AdapterAddress}
	digest, err := signer.Hash(cfg)
	if err != nil {
		t.Fatal(err)
	}
	expected := common.HexToHash(eip712VectorDigest)
	if digest != expected {
		t.Fatalf("eip712 digest mismatch: got %s want %s", digest.Hex(), expected.Hex())
	}
}
