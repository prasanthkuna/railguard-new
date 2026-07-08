package watcher

import (
	"context"
	"math/big"
	"strings"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/railguard/signgate/internal/config"
	"github.com/railguard/signgate/internal/store"
	"github.com/rs/zerolog"
)

type captureChainExecStore struct {
	store.Noop
	got *store.ChainExecution
}

func (c *captureChainExecStore) RecordChainExecution(_ context.Context, exec store.ChainExecution) error {
	copy := exec
	c.got = &copy
	return nil
}

func TestIngestLogParsesExecutionAllowed(t *testing.T) {
	account := common.HexToAddress("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
	sessionID := crypto.Keccak256Hash([]byte("session"))
	nonceKey := big.NewInt(424242)
	frameSpend := big.NewInt(50_000_000)
	totalSpend := big.NewInt(50_000_000)
	txHash := common.HexToHash("0xabc123def456")

	data := make([]byte, 64)
	copy(data[0:32], common.LeftPadBytes(frameSpend.Bytes(), 32))
	copy(data[32:64], common.LeftPadBytes(totalSpend.Bytes(), 32))

	lg := types.Log{
		Topics: []common.Hash{
			executionAllowedSig,
			common.BytesToHash(common.LeftPadBytes(account.Bytes(), 32)),
			sessionID,
			common.BytesToHash(common.LeftPadBytes(nonceKey.Bytes(), 32)),
		},
		Data:        data,
		BlockNumber: 42,
		TxHash:      txHash,
		Index:       7,
	}

	st := &captureChainExecStore{}
	r := &Reconciler{log: zerolog.Nop(), store: st, cfg: config.Config{}}
	if err := r.ingestLog(context.Background(), lg); err != nil {
		t.Fatal(err)
	}
	if st.got == nil {
		t.Fatal("expected RecordChainExecution to be called")
	}
	if st.got.Account != "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266" {
		t.Fatalf("account got %s", st.got.Account)
	}
	if st.got.SessionID != sessionID.Hex() {
		t.Fatalf("sessionId got %s want %s", st.got.SessionID, sessionID.Hex())
	}
	if st.got.NonceKey != "424242" {
		t.Fatalf("nonceKey got %s", st.got.NonceKey)
	}
	if st.got.FrameSpend != "50000000" {
		t.Fatalf("frameSpend got %s", st.got.FrameSpend)
	}
	if st.got.TotalSpendAfter != "50000000" {
		t.Fatalf("totalSpendAfter got %s", st.got.TotalSpendAfter)
	}
	if st.got.BlockNumber != 42 {
		t.Fatalf("blockNumber got %d", st.got.BlockNumber)
	}
	if st.got.TxHash != strings.ToLower(txHash.Hex()) {
		t.Fatalf("txHash got %s want %s", st.got.TxHash, txHash.Hex())
	}
	if st.got.LogIndex != 7 {
		t.Fatalf("logIndex got %d", st.got.LogIndex)
	}
}

func TestIngestLogSkipsMalformedTopics(t *testing.T) {
	r := &Reconciler{log: zerolog.Nop(), store: store.NewNoop(), cfg: config.Config{}}
	if err := r.ingestLog(context.Background(), types.Log{Topics: []common.Hash{{}}}); err != nil {
		t.Fatal(err)
	}
}

func TestExecutionAllowedTopicHash(t *testing.T) {
	want := crypto.Keccak256Hash([]byte("ExecutionAllowed(address,bytes32,uint192,uint256,uint256)"))
	if executionAllowedSig != want {
		t.Fatalf("topic mismatch got %s want %s", executionAllowedSig.Hex(), want.Hex())
	}
}
