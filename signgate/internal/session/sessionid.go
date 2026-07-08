package session

import (
	"encoding/hex"
	"math/big"
	"strings"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
)

type Config struct {
	Account          string
	NonceKey         string
	SessionKey       string
	Token            string
	AllowedTarget    string
	AllowedRecipient string
	AllowedSelector  string
	MaxPerTransfer   string
	MaxTotalSpend    string
	ValidAfter       int64
	ValidUntil       int64
	AllowBatch       bool
	PolicyHash       string
	ChainID          int64
	AdapterAddress   string
}

func parseBool(b bool) byte {
	if b {
		return 1
	}
	return 0
}

func mustBig(s string) *big.Int {
	v, ok := new(big.Int).SetString(s, 10)
	if !ok {
		panic("invalid big int: " + s)
	}
	return v
}

func mustAddr(s string) common.Address {
	return common.HexToAddress(s)
}

func mustBigInt64(v int64) *big.Int {
	return big.NewInt(v)
}

func mustSelector(s string) [4]byte {
	b, err := hex.DecodeString(strings.TrimPrefix(s, "0x"))
	if err != nil || len(b) != 4 {
		panic("invalid selector")
	}
	var out [4]byte
	copy(out[:], b)
	return out
}

// SessionConfigPhysicalHash matches Solidity SessionId.sessionConfigPhysicalHash.
func SessionConfigPhysicalHash(cfg Config) (common.Hash, error) {
	uint256Ty, _ := abi.NewType("uint256", "", nil)
	uint48Ty, _ := abi.NewType("uint48", "", nil)
	boolTy, _ := abi.NewType("bool", "", nil)
	bytes4Ty, _ := abi.NewType("bytes4", "", nil)
	addressTy, _ := abi.NewType("address", "", nil)

	args := abi.Arguments{
		{Type: addressTy},
		{Type: addressTy},
		{Type: addressTy},
		{Type: addressTy},
		{Type: bytes4Ty},
		{Type: uint256Ty},
		{Type: uint256Ty},
		{Type: uint48Ty},
		{Type: uint48Ty},
		{Type: boolTy},
	}

	allowedTarget := cfg.AllowedTarget
	if allowedTarget == "" {
		allowedTarget = cfg.Token
	}

	packed, err := args.Pack(
		mustAddr(cfg.SessionKey),
		mustAddr(cfg.Token),
		mustAddr(allowedTarget),
		mustAddr(cfg.AllowedRecipient),
		mustSelector(cfg.AllowedSelector),
		mustBig(cfg.MaxPerTransfer),
		mustBig(cfg.MaxTotalSpend),
		mustBigInt64(cfg.ValidAfter),
		mustBigInt64(cfg.ValidUntil),
		cfg.AllowBatch,
	)
	if err != nil {
		return common.Hash{}, err
	}
	return crypto.Keccak256Hash(packed), nil
}

// DeriveSessionID matches Solidity SessionId.deriveSessionId.
func DeriveSessionID(cfg Config) (common.Hash, error) {
	physical, err := SessionConfigPhysicalHash(cfg)
	if err != nil {
		return common.Hash{}, err
	}

	uint256Ty, _ := abi.NewType("uint256", "", nil)
	uint192Ty, _ := abi.NewType("uint192", "", nil)
	bytes32Ty, _ := abi.NewType("bytes32", "", nil)
	addressTy, _ := abi.NewType("address", "", nil)

	nonceKey := mustBig(cfg.NonceKey)
	args := abi.Arguments{
		{Type: uint256Ty},
		{Type: addressTy},
		{Type: addressTy},
		{Type: uint192Ty},
		{Type: bytes32Ty},
	}

	packed, err := args.Pack(
		big.NewInt(cfg.ChainID),
		mustAddr(cfg.AdapterAddress),
		mustAddr(cfg.Account),
		nonceKey,
		physical,
	)
	if err != nil {
		return common.Hash{}, err
	}
	return crypto.Keccak256Hash(packed), nil
}
