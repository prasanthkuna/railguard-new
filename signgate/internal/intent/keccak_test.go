package intent

import (
	"encoding/json"
	"testing"

	"github.com/ethereum/go-ethereum/crypto"
)

func TestHashUsesKeccak256(t *testing.T) {
	ci := CanonicalIntent{
		AgentID:      "agent_support_bot_1",
		Account:      "0x0000000000000000000000000000000000000001",
		ChainID:      84532,
		Token:        "0x00000000000000000000000000000000000000aa",
		Recipient:    "0x0000000000000000000000000000000000000b01",
		AmountAtomic: "100000000",
		Domain:       "api.vendor.com",
		Path:         "/v1/report",
		Method:       "POST",
	}
	b, err := json.Marshal(ci)
	if err != nil {
		t.Fatal(err)
	}
	got, err := Hash(ci)
	if err != nil {
		t.Fatal(err)
	}
	want := crypto.Keccak256Hash(b).Hex()
	if got != want {
		t.Fatalf("hash mismatch got %s want %s", got, want)
	}
}
