package watcher

import (
	"context"
	"math/big"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/railguard/signgate/internal/config"
	"github.com/railguard/signgate/internal/store"
	"github.com/rs/zerolog"
)

var executionAllowedSig = crypto.Keccak256Hash([]byte("ExecutionAllowed(address,bytes32,uint192,uint256,uint256)"))

// Reconciler ingests on-chain ExecutionAllowed events for mandatory v1 reconciliation.
type Reconciler struct {
	log       zerolog.Logger
	store     store.Repository
	cfg       config.Config
	client    *ethclient.Client
	lastBlock uint64
}

func New(log zerolog.Logger, st store.Repository, cfg config.Config) *Reconciler {
	return &Reconciler{
		log:   log,
		store: st,
		cfg:   cfg,
	}
}

func (r *Reconciler) Run(ctx context.Context) {
	interval := time.Duration(r.cfg.WatcherPollSeconds) * time.Second
	if interval <= 0 {
		interval = 5 * time.Second
	}

	if r.cfg.HookAddress == "" || r.cfg.RPCURL == "" {
		r.log.Warn().Msg("watcher disabled: HOOK_ADDRESS or RPC_URL not configured")
		return
	}

	client, err := ethclient.DialContext(ctx, r.cfg.RPCURL)
	if err != nil {
		r.log.Error().Err(err).Msg("watcher rpc dial failed")
		return
	}
	r.client = client
	defer client.Close()

	if cursor, err := r.store.GetWatcherBlockCursor(ctx); err == nil {
		r.lastBlock = cursor
	} else if r.cfg.WatcherStartBlock > 0 {
		r.lastBlock = uint64(r.cfg.WatcherStartBlock - 1)
	} else {
		r.lastBlock = 0
	}

	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	r.log.Info().
		Str("hook", r.cfg.HookAddress).
		Uint64("fromBlock", r.lastBlock+1).
		Int64("rescanBlocks", r.cfg.WatcherRescanBlocks).
		Msg("watcher reconciliation loop started")

	for {
		select {
		case <-ctx.Done():
			r.log.Info().Msg("watcher stopped")
			return
		case <-ticker.C:
			if err := r.tick(ctx); err != nil {
				r.log.Warn().Err(err).Msg("watcher tick failed")
			}
		}
	}
}

func (r *Reconciler) tick(ctx context.Context) error {
	staleSec := r.cfg.UserOpStaleSeconds
	if staleSec <= 0 {
		staleSec = 300
	}
	cutoff := time.Now().UTC().Add(-time.Duration(staleSec) * time.Second)
	if n, err := r.store.MarkStaleUserOpsReconciliationRequired(ctx, cutoff); err != nil {
		r.log.Warn().Err(err).Msg("mark stale userops")
	} else if n > 0 {
		r.log.Warn().Int("count", n).Msg("userops marked RECONCILIATION_REQUIRED")
	}
	return r.poll(ctx)
}

func (r *Reconciler) poll(ctx context.Context) error {
	head, err := r.client.BlockNumber(ctx)
	if err != nil {
		return err
	}

	confirm := uint64(r.cfg.WatcherConfirmation)
	safeHead := head
	if confirm > 0 && head > confirm {
		safeHead = head - confirm
	}
	if safeHead <= r.lastBlock {
		return nil
	}

	rescan := uint64(r.cfg.WatcherRescanBlocks)
	from := r.lastBlock + 1
	if rescan > 0 && r.lastBlock >= rescan {
		rewind := r.lastBlock - rescan + 1
		if rewind < from {
			from = rewind
		}
	}
	to := safeHead

	hook := common.HexToAddress(r.cfg.HookAddress)
	logs, err := r.client.FilterLogs(ctx, ethereum.FilterQuery{
		FromBlock: new(big.Int).SetUint64(from),
		ToBlock:   new(big.Int).SetUint64(to),
		Addresses: []common.Address{hook},
		Topics:    [][]common.Hash{{executionAllowedSig}},
	})
	if err != nil {
		return err
	}

	for _, lg := range logs {
		if err := r.ingestLog(ctx, lg); err != nil {
			r.log.Warn().Err(err).Str("tx", lg.TxHash.Hex()).Msg("failed to ingest ExecutionAllowed")
		}
	}

	r.lastBlock = to
	if err := r.store.SetWatcherBlockCursor(ctx, to); err != nil {
		r.log.Warn().Err(err).Msg("failed to persist watcher cursor")
	}
	return nil
}

func (r *Reconciler) ingestLog(ctx context.Context, lg types.Log) error {
	if len(lg.Topics) < 4 {
		return nil
	}
	account := common.BytesToAddress(lg.Topics[1].Bytes())
	sessionID := lg.Topics[2]
	nonceKey := new(big.Int).SetBytes(lg.Topics[3].Bytes()).String()

	var frameSpend, totalSpendAfter string
	if len(lg.Data) >= 64 {
		frameSpend = new(big.Int).SetBytes(lg.Data[0:32]).String()
		totalSpendAfter = new(big.Int).SetBytes(lg.Data[32:64]).String()
	}

	return r.store.RecordChainExecution(ctx, store.ChainExecution{
		Account:         strings.ToLower(account.Hex()),
		SessionID:       sessionID.Hex(),
		NonceKey:        nonceKey,
		FrameSpend:      frameSpend,
		TotalSpendAfter: totalSpendAfter,
		BlockNumber:     int64(lg.BlockNumber),
		TxHash:          strings.ToLower(lg.TxHash.Hex()),
		LogIndex:        int(lg.Index),
	})
}
