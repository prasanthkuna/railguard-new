package receipt

import (
	"crypto/ecdsa"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum/crypto"
)

type Payload struct {
	ReceiptVersion string   `json:"receiptVersion"`
	DecisionID     string   `json:"decisionId"`
	Decision       string   `json:"decision"`
	ReasonCodes    []string `json:"reasonCodes"`
	AgentID        string   `json:"agentId"`
	IntentHash     string   `json:"intentHash"`
	PolicyHash     string   `json:"policyHash"`
	SessionID      string   `json:"sessionId,omitempty"`
	NonceKey       string   `json:"nonceKey,omitempty"`
	ChainID        int64    `json:"chainId"`
	Token          string   `json:"token"`
	Recipient      string   `json:"recipient"`
	AmountAtomic   string   `json:"amountAtomic"`
	AllowBatch     bool     `json:"allowBatch"`
	ValidUntil     int64    `json:"validUntil,omitempty"`
	SignerKeyID    string   `json:"signerKeyID"`
	CreatedAt      string   `json:"createdAt"`
}

type Signed struct {
	Payload     Payload `json:"payload"`
	ReceiptHash string  `json:"receiptHash"`
	Signature   string  `json:"signature"`
}

type Signer struct {
	KeyID      string
	PrivateKey string
}

func (s Signer) Sign(p Payload) (Signed, error) {
	p.ReceiptVersion = "railguard.v1"
	p.SignerKeyID = s.KeyID
	if p.CreatedAt == "" {
		p.CreatedAt = time.Now().UTC().Format(time.RFC3339)
	}
	b, err := json.Marshal(p)
	if err != nil {
		return Signed{}, err
	}
	sum := sha256.Sum256(b)
	hash := "0x" + hex.EncodeToString(sum[:])

	key, err := crypto.HexToECDSA(strings.TrimPrefix(s.PrivateKey, "0x"))
	if err != nil {
		return Signed{}, err
	}
	sig, err := signHash(key, sum[:])
	if err != nil {
		return Signed{}, err
	}

	return Signed{
		Payload:     p,
		ReceiptHash: hash,
		Signature:   "0x" + hex.EncodeToString(sig),
	}, nil
}

func signHash(key *ecdsa.PrivateKey, digest []byte) ([]byte, error) {
	sig, err := crypto.Sign(digest, key)
	if err != nil {
		return nil, err
	}
	// go-ethereum v1.14+ may already return V as 27/28 on the wire.
	if sig[64] < 27 {
		sig[64] += 27
	}
	return sig, nil
}

func HashString(p Payload) (string, error) {
	b, err := json.Marshal(p)
	if err != nil {
		return "", err
	}
	sum := sha256.Sum256(b)
	return "0x" + hex.EncodeToString(sum[:]), nil
}

func ValidatePrivateKey(hexKey string) error {
	if hexKey == "" {
		return fmt.Errorf("missing receipt signer key")
	}
	_, err := crypto.HexToECDSA(strings.TrimPrefix(hexKey, "0x"))
	return err
}
