package eip712

import (
	"fmt"
	"strings"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/common/math"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/signer/core/apitypes"
	"github.com/railguard/signgate/internal/session"
)

const sessionAuthType = "SessionAuthorization(address account,uint192 nonceKey,address sessionKey,address token,address allowedTarget,address allowedRecipient,bytes4 allowedSelector,uint256 maxPerTransfer,uint256 maxTotalSpend,uint48 validAfter,uint48 validUntil,bool allowBatch,bytes32 policyHash)"

type Signer struct {
	ChainID            int64
	AdapterAddress     string
	RailguardSignerKey string
}

func (s Signer) TypedData(cfg session.Config) apitypes.TypedData {
	allowedTarget := cfg.Token
	if cfg.AllowedTarget != "" {
		allowedTarget = cfg.AllowedTarget
	}
	policyHash := common.HexToHash(cfg.PolicyHash)
	nonceKey, _ := math.ParseBig256(cfg.NonceKey)

	return apitypes.TypedData{
		Types: apitypes.Types{
			"EIP712Domain": {
				{Name: "name", Type: "string"},
				{Name: "version", Type: "string"},
				{Name: "chainId", Type: "uint256"},
				{Name: "verifyingContract", Type: "address"},
			},
			"SessionAuthorization": {
				{Name: "account", Type: "address"},
				{Name: "nonceKey", Type: "uint192"},
				{Name: "sessionKey", Type: "address"},
				{Name: "token", Type: "address"},
				{Name: "allowedTarget", Type: "address"},
				{Name: "allowedRecipient", Type: "address"},
				{Name: "allowedSelector", Type: "bytes4"},
				{Name: "maxPerTransfer", Type: "uint256"},
				{Name: "maxTotalSpend", Type: "uint256"},
				{Name: "validAfter", Type: "uint48"},
				{Name: "validUntil", Type: "uint48"},
				{Name: "allowBatch", Type: "bool"},
				{Name: "policyHash", Type: "bytes32"},
			},
		},
		PrimaryType: "SessionAuthorization",
		Domain: apitypes.TypedDataDomain{
			Name:              "Railguard",
			Version:           "1",
			ChainId:           math.NewHexOrDecimal256(s.ChainID),
			VerifyingContract: s.AdapterAddress,
		},
		Message: apitypes.TypedDataMessage{
			"account":          cfg.Account,
			"nonceKey":         nonceKey,
			"sessionKey":       cfg.SessionKey,
			"token":            cfg.Token,
			"allowedTarget":    allowedTarget,
			"allowedRecipient": cfg.AllowedRecipient,
			"allowedSelector":  hexutil.MustDecode(cfg.AllowedSelector),
			"maxPerTransfer":   cfg.MaxPerTransfer,
			"maxTotalSpend":    cfg.MaxTotalSpend,
			"validAfter":       math.NewHexOrDecimal256(cfg.ValidAfter),
			"validUntil":       math.NewHexOrDecimal256(cfg.ValidUntil),
			"allowBatch":       cfg.AllowBatch,
			"policyHash":       policyHash,
		},
	}
}

func (s Signer) Hash(cfg session.Config) (common.Hash, error) {
	td := s.TypedData(cfg)
	hashBytes, _, err := apitypes.TypedDataAndHash(td)
	if err != nil {
		return common.Hash{}, err
	}
	return common.BytesToHash(hashBytes), nil
}

func (s Signer) SignRailguard(cfg session.Config) (digest common.Hash, sig []byte, err error) {
	if s.RailguardSignerKey == "" {
		return common.Hash{}, nil, fmt.Errorf("railguard signer key not configured")
	}
	digest, err = s.Hash(cfg)
	if err != nil {
		return common.Hash{}, nil, err
	}
	key, err := crypto.HexToECDSA(strings.TrimPrefix(s.RailguardSignerKey, "0x"))
	if err != nil {
		return common.Hash{}, nil, err
	}
	sig, err = crypto.Sign(digest.Bytes(), key)
	if err != nil {
		return common.Hash{}, nil, err
	}
	sig[64] += 27
	return digest, sig, nil
}

func TypeHash() [32]byte {
	return crypto.Keccak256Hash([]byte(sessionAuthType))
}
