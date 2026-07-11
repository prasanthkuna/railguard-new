# Failure Modes Fixed

Bug classes discovered in the three-project security audit (2026-07-11), how they were exploited, what we shipped, and how to prove each fix.

| Bug class | Exploit path | Fix | Proof |
|-----------|--------------|-----|-------|
| **Mutable ALLOW** | Get ALLOW on small caps; mutate `maxPerTransfer` / `maxTotalSpend` on same intent hash; cosign larger session | Limits included in canonical intent hash; `SaveIntent` uses `ON CONFLICT DO NOTHING` | `signgate/internal/intent/intent_test.go` (`TestHashIncludesLimits`); Go tests |
| **x402 budget race** | Concurrent payments all read same window headroom; all pass; total spend exceeds cap | `authorizePayment`: atomic `claimReplay` + `reserveBudget` → `commitAuthorization` / `releaseAuthorization` | `x402-guard/packages/policy/src/authorize.test.ts`; `fault-injection.test.ts` |
| **Post-broadcast lie** | CDP returns tx hash; DB/audit fails; status `failed`; retry double-pays | Track `broadcastedTxHash`; post-broadcast errors → `unknown`/`submitted`; reconciler cron | `coinbase/apps/api/payment-state.test.ts`; `execution-claim.test.ts` |
| **FIFO reconciliation** | Watcher commits oldest pending reservation per session, not matching execution | `ExecutionAllowed` emits `executionDigest`; store matches by digest | `signgate/internal/watcher/watcher_test.go`; `scripts/e2e-happy-path.ps1` |
| **Reservation expiry leak** | Redis ZSET entry expires; metadata gone; aggregate budget never released | Durable ZSET member; metadata TTL 2× deadline; atomic release | `signgate/internal/reservation/reservation_test.go` |
| **Client-trusted reserve** | Caller supplies `amountAtomic` / `intentHash` not bound to session | `GetSessionReserveSnapshot` validates agent, intent, limits, validity | `signgate` API + store tests |
| **Approval snapshot drift** | Approve policy run A; execute creates run B; mismatch or NULL bypass | `policy_snapshot_hash` on approval; execute uses snapshot eval | `coinbase/apps/api/policySnapshot.ts` |
| **Audit chain fork** | Advisory lock + insert not in one transaction | `appendAudit` in single DB transaction | `coinbase` API integration |
| **Reverted tx confirmed** | Receipt mined but `status !== success` | `waitForTransferConfirmation` checks receipt status | `coinbase/apps/api/providers.ts` |
| **x402 replay race** | `hasReplay` then `markReplay` separately | Atomic `claimReplay` | `x402-guard/packages/policy/src/storage.test.ts` |
| **Spend before confirm** | Payment marked confirmed before x402 budget committed | Reserve before pay; commit after confirm; release on failure | `x402-guard/packages/middleware/src/stateStore.test.ts` |
| **Linux CI lockfile** | `npm ci` missing @emnapi peers on Ubuntu | Regenerated `sdk/package-lock.json` on Node 20 Linux | `railguard-new` CI green |
| **Docker schema drift** | Postgres volume missing migrations 003/004 | `apply-db-migrations.ps1` + compose init mounts | `scripts/e2e-happy-path.ps1` |

## Proof commands

```powershell
# x402 atomic budget + fault injection
cd x402-guard
bun test packages/policy/src/authorize.test.ts packages/policy/src/fault-injection.test.ts

# SignGate + watcher
cd railguard-new/signgate
go test ./internal/watcher ./internal/intent ./internal/reservation -v

# CDP payment state machine
cd coinbase
bun test apps/api/payment-state.test.ts apps/api/execution-claim.test.ts

# Full stack
cd railguard-new
docker compose up -d --build
powershell -File .\scripts\apply-db-migrations.ps1
powershell -File .\scripts\e2e-happy-path.ps1
```

## Still open (honest)

| Gap | Mitigation today | Next step |
|-----|------------------|-----------|
| Deep reorg rewind | Block-hash cursor; confirmation depth configurable | Full rewind state machine |
| HSM / MPC signers | Dev keys in v0.1 | KMS integration for SignGate cosign |
| Postgres fault-injection at API boundary | Unit tests on primitives | Integration tests with testcontainers |
| CDP dependency advisories | Scoped workspaces; biome ignores non-deploy paths | Lockfile regen + targeted upgrades |
