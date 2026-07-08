# Security Review Checklist

Railguard v1 is a **hiring-grade security primitive**, not a production payment product. Use this checklist when reviewing the repo.

## Core invariants

| Invariant | Enforced by |
|-----------|-------------|
| Wrong recipient/token/target/selector blocked | `RailguardExecutionHook._validateLeaf` |
| Per-transfer and cumulative caps | Hook spend maps + `maxTotalSpend` |
| Session expiry / not-yet-valid | Hook + adapter |
| Execution digest replay | `usedExecutions` mapping |
| Delegatecall / unknown modes | Hook rejects before execution |
| Batch hidden leaf attacks | All leaves validated; one bad leaf reverts entire batch |
| `allowBatch == false` | Hook rejects `CALLTYPE_BATCH` |
| `allowedTarget == token` (v1) | Registration + hook |
| Dual-sig registration | Owner EIP-712 + Railguard EIP-712 |

**Off-chain policy (OPA) is advisory.** On-chain hook is the physical law.

## Known non-goals (v1)

- Paymaster / gas sponsorship (v1.1)
- Generic ERC-7579 account compatibility
- Arbitrary router / multicall parsing
- Merkle allowlists
- Human approval (`REQUIRE_APPROVAL`)
- Mainnet deployment or real user funds

## E2E scripts

| Script | Scope |
|--------|--------|
| `e2e-smoke.ps1` | API smoke — health + intent evaluate |
| `e2e-happy-path.ps1` | Canonical PRD E2E — deploy, cosign, on-chain execute, watcher ingestion, receipt |
| `demo-onchain.ps1` | Foundry PRD demo (allow + 3 blocks) |

```powershell
powershell -File scripts/e2e-happy-path.ps1
```

## Watcher limitations

- Confirmation depth only (default 1 block)
- Idempotent re-scan window (`WATCHER_RESCAN_BLOCKS`, default 12)
- Stale `USEROP_SUBMITTED` → `RECONCILIATION_REQUIRED` after `USEROP_STALE_SECONDS`
- **No deep reorg rewind** — manual reconciliation for chain reorganizations

## Forge lint notes (non-blocking)

Foundry may warn on `block.timestamp` in session validity checks and `bytes4(callData)` casts in the execution decoder. These are intentional v1 patterns; see `contracts/src` and `docs/THREAT_MODEL.md`.

## API security

- Mutating routes require `X-SignGate-API-Key`
- Production rejects dev default API key (`config.Validate`)
- Receipt reads require API key (not public)

## Reviewer yes/no

- [ ] Foundry threat matrix passes including `ThreatMatrixGaps.t.sol`
- [ ] PRD demo script passes
- [ ] sessionId / EIP-712 / receipt hash vectors agree across Solidity, Go, TS (SDK: 12/12 Vitest)
- [ ] OPA differential vectors: policy never looser than hook floor
- [ ] SignGate fails startup without API key in production config
- [ ] Canonical E2E (`e2e-happy-path.ps1`) proves watcher ingested `ExecutionAllowed` for the same session tx
- [ ] `docker compose up` alone is API smoke only; canonical E2E requires `e2e-happy-path.ps1`
