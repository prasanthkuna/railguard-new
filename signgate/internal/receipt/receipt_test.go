package receipt

import (
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
)

func TestSignAndRecoverReceiptSigner(t *testing.T) {
	keyHex := "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
	key, err := crypto.HexToECDSA(keyHex[2:])
	if err != nil {
		t.Fatal(err)
	}
	expected := crypto.PubkeyToAddress(key.PublicKey)

	signer := Signer{KeyID: "test", PrivateKey: keyHex}
	signed, err := signer.Sign(Payload{
		DecisionID:   "dec_sig_test",
		Decision:     "ALLOW",
		ReasonCodes:  []string{"WITHIN_LIMITS"},
		AgentID:      "agent_support_bot_1",
		IntentHash:   "0x96734b72ae38ed4166ef08446996462802dd2c7577fe608fdc0c6371a571d150",
		PolicyHash:   "0x1111111111111111111111111111111111111111111111111111111111111111",
		ChainID:      84532,
		Token:        "0x00000000000000000000000000000000000000aa",
		Recipient:    "0x0000000000000000000000000000000000000b01",
		AmountAtomic: "100000000",
		CreatedAt:    "2026-07-08T00:00:00Z",
	})
	if err != nil {
		t.Fatal(err)
	}

	hash := common.HexToHash(signed.ReceiptHash)
	sig := common.FromHex(signed.Signature)
	if sig[64] >= 27 {
		sig[64] -= 27
	}
	pub, err := crypto.SigToPub(hash.Bytes(), sig)
	if err != nil {
		t.Fatal(err)
	}
	if crypto.PubkeyToAddress(*pub) != expected {
		t.Fatal("recovered signer mismatch")
	}
}
