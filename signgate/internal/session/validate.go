package session

import (
	"encoding/hex"
	"fmt"
	"math/big"
	"strings"
)

func ValidateV1(cfg Config) error {
	if strings.TrimSpace(cfg.Account) == "" || strings.TrimSpace(cfg.SessionKey) == "" || strings.TrimSpace(cfg.Token) == "" {
		return fmt.Errorf("account, sessionKey, and token are required")
	}
	if strings.TrimSpace(cfg.AllowedRecipient) == "" {
		return fmt.Errorf("allowedRecipient is required")
	}
	if cfg.AllowedTarget != "" && !strings.EqualFold(cfg.AllowedTarget, cfg.Token) {
		return fmt.Errorf("allowedTarget must equal token in v1")
	}
	if cfg.AllowedSelector != "" && !strings.EqualFold(cfg.AllowedSelector, "0xa9059cbb") {
		return fmt.Errorf("only transfer(address,uint256) selector supported in v1")
	}
	if strings.TrimSpace(cfg.NonceKey) == "" {
		return fmt.Errorf("nonceKey is required")
	}
	if _, ok := new(big.Int).SetString(cfg.NonceKey, 10); !ok {
		return fmt.Errorf("invalid nonceKey")
	}
	maxPer, ok := new(big.Int).SetString(cfg.MaxPerTransfer, 10)
	if !ok || maxPer.Sign() <= 0 {
		return fmt.Errorf("maxPerTransfer must be positive")
	}
	maxTotal, ok := new(big.Int).SetString(cfg.MaxTotalSpend, 10)
	if !ok || maxTotal.Sign() <= 0 {
		return fmt.Errorf("maxTotalSpend must be positive")
	}
	if maxTotal.Cmp(maxPer) < 0 {
		return fmt.Errorf("maxTotalSpend must be >= maxPerTransfer")
	}
	if cfg.ValidUntil <= cfg.ValidAfter {
		return fmt.Errorf("invalid validity window")
	}
	if strings.TrimSpace(cfg.PolicyHash) == "" {
		return fmt.Errorf("policyHash is required")
	}
	if _, err := hex.DecodeString(strings.TrimPrefix(cfg.PolicyHash, "0x")); err != nil || len(strings.TrimPrefix(cfg.PolicyHash, "0x")) != 64 {
		return fmt.Errorf("policyHash must be 32-byte hex")
	}
	return nil
}
