# Three-Project Security Re-Audit

Date: 2026-07-11

Reviewed heads:

- `railguard-new@82178d9`
- `x402-guard@e50d607`
- `railguard-cdp@873f93a`

Scope: Solidity contracts, SignGate, Railguard SDK/OPA, x402 guard packages, Railguard CDP API/auth/policy/audit/payment state, migrations, tests, CI, dependency health, and canonical demos.

This is a senior architecture/code review, not a formal third-party audit.

## Verdict

The project is materially stronger than the first audit. Negative-amount bypasses, domain spoofing, permissionless hook initialization, malformed-signature reverts, client-provided session caps, global `lastReceipt` settlement, silent live-to-demo fallback, and the first Coinbase double-claim bug are improved or closed.

It is not yet production-safe. The remaining failures are concentrated in atomicity and truth convergence: policy snapshots can mutate after ALLOW, x402 budget authorization is check-then-act, post-broadcast errors can still be classified as failed, reservation expiry repair cannot recover expired metadata, approval binding is unusable, and the audit lock is not held across the append transaction.

## Critical

### C-01: An old ALLOW decision can authorize newly mutated session limits

Locations:

- `signgate/internal/intent/intent.go:32-42`
- `signgate/internal/api/server.go:82-126`
- `signgate/internal/store/store.go:85-96`
- `signgate/internal/store/store.go:200-231`

The canonical intent hash excludes `maxPerTransfer`, `maxTotalSpend`, and `allowBatch`. `SaveIntent` uses `ON CONFLICT (intent_hash) DO UPDATE` to overwrite those fields before OPA evaluation, while existing decisions reference only `intent_hash`.

Attack:

1. Obtain an ALLOW decision for safe limits.
2. Re-submit the same canonical payment with larger limits.
3. The intent row is updated even if the second policy result is BLOCK or persistence later fails.
4. Register using the old ALLOW decision; `GetAllowDecision` reads the mutated limits.

Impact: SignGate may cosign physical limits that were never approved by the consumed decision.

Required fix: persist an immutable decision snapshot containing every signed session field, or include all physical fields in the canonical authorization hash. Never update security-relevant facts behind an existing decision.

### C-02: Concurrent x402 payments can exceed rolling-window budgets

Locations:

- `x402-guard/packages/policy/src/evaluateWithStore.ts:65-69`
- `x402-guard/packages/middleware/src/index.ts:94-134`
- `x402-guard/packages/middleware/src/index.ts:88-92`
- `coinbase/apps/api/x402GuardDbStore.ts:23-42`
- `coinbase/apps/api/api.ts:822-950`

Budget evaluation reads the current sum, the external payment runs, and spend is inserted later. Multiple distinct payments can all observe the same available headroom and then settle above the cap.

Durable storage does not solve this; authorization must be atomic.

Required fix: replace `sumSpendInWindow + recordSpend` with `reserveBudget -> commit/release` in one serializable transaction/advisory lock per agent and policy window. The authorization must return a unique durable handle consumed by settlement.

### C-03: Post-broadcast failures can still be marked failed

Locations: `coinbase/apps/api/api.ts:883-990`

After CDP returns a transaction hash, the update to `submitted`, confirmation, confirmed update, audit append, receipt settlement, or spend commit can fail. Classification uses error-message regexes, not whether broadcast occurred. A DB error after broadcast can therefore set status `failed`, even though funds may have moved.

Impact: a new payment intent can cause duplicate payment.

Required fix: track `broadcastedTxHash` explicitly. After a hash exists, every error is `submitted/unknown` until chain reconciliation proves confirmed or reverted. Never infer financial finality from exception text.

## High

### H-01: Reservation expiry repair still leaks aggregate budget

Locations: `signgate/internal/reservation/reservation.go:56-69`, `reservation.go:125-132`, `reservation.go:147-195`

Reservation metadata and the expiry score use the same TTL/deadline. When the sweeper sees an expired ZSET entry, the metadata key is normally already expired; `ReleaseReservation` returns without subtracting the amount. The sweeper ignores release errors and removes the index entry, making repair impossible.

Fix: keep metadata longer than the reservation deadline or store session/amount in durable expiry data. Release and index removal must be one atomic Lua/transaction operation; do not discard failures.

### H-02: “1:1 reconciliation” still commits by ordering, not identity

Locations:

- `contracts/src/RailguardExecutionHook.sol:22-28`
- `signgate/internal/store/store.go:392-411`

`ExecutionAllowed` emits no reservation/execution identifier. The watcher commits the oldest pending reservation for the session and ignores the supplied transaction hash. This is one-row-at-a-time, but not one-to-one proof. Direct executions or out-of-order UserOps misattribute reservations.

Fix: emit a canonical `executionId`/UserOp identity and reconcile by that exact value.

### H-03: Reservation input remains insufficiently bound

Locations: `signgate/internal/api/server.go:269-299`

The server loads `maxTotalSpend`, but still accepts client-supplied `amountAtomic`, `intentHash`, and `agentId`. It does not enforce session `maxPerTransfer`, ownership, active validity, or that the amount/intent belongs to the session. A caller can reserve the entire total cap for a transaction the hook will reject.

Fix: load the full session/intent snapshot server-side and validate state and amount before reservation.

### H-04: Idempotent reservation retry can release the original reservation

Locations: `reservation.go:90-92`, `server.go:289-297`

Redis returns the existing reservation ID for an idempotent retry. `SaveReservation` then attempts another insert, which can fail on unique keys; the handler releases the existing valid Redis reservation and returns 500.

Fix: make Postgres reservation persistence idempotent and return the existing row only when all immutable request facts match.

### H-05: Approval binding blocks legitimate escalated execution and permits legacy bypass

Locations:

- `coinbase/apps/api/api.ts:659-669`
- `coinbase/apps/api/api.ts:1567-1586`

Approval binds to the latest policy run. Execution immediately creates a new policy run, so the approved run ID no longer matches. Escalated invoices cannot execute. Conversely, legacy approvals with `NULL policy_run_id` skip the mismatch check.

Fix: compute a deterministic policy snapshot hash, approve that immutable snapshot, and re-evaluate without creating a new identity when facts are unchanged. Reject null/unbound approvals.

### H-06: Audit-chain locking is outside a transaction

Locations: `coinbase/apps/api/api.ts:1770-1824`

`pg_advisory_xact_lock`, head read, event insert, and head update are separate database calls with no explicit transaction. The transaction-scoped lock is released at the end of the first statement; `FOR UPDATE` is also released before insert. Concurrent appends can still fork or overwrite the head.

Fix: execute lock, head read, insert, and head update through one DB transaction/connection.

### H-07: Reverted transactions may be marked confirmed

Locations: `coinbase/apps/api/providers.ts:32-40`, `coinbase/apps/api/api.ts:899-916`

`waitForTransactionReceipt` is called with one confirmation, but its returned receipt is discarded and `receipt.status` is never checked. A mined reverted transaction can be persisted as confirmed/executed.

Fix: require `receipt.status === "success"`; persist block hash/number and reconcile through configurable confirmation depth.

### H-08: No reconciler closes submitted/unknown payment states

The API correctly refuses retries for ambiguous states, but no worker shown in this repo resolves them by querying chain/provider state. Payments can remain permanently stuck.

Fix: add one small reconciliation worker for `submitted/unknown`; do not add a new service or queue.

### H-09: Watcher confirmation and reorg defects remain

Locations: `signgate/internal/watcher/watcher.go:100-146`

When `head <= confirmationDepth`, the watcher processes `head` instead of waiting. Rescan does not remove orphaned logs or roll back committed reservation state. Failed ingestions do not prevent cursor advancement.

Fix: persist block hashes, wait correctly for safe head, transactionally ingest each range, and remove/reverse orphaned records.

### H-10: Redis aggregate expires independently of on-chain/session lifetime

Location: `signgate/internal/reservation/reservation.go:125-128`

The session aggregate has a fixed 24-hour TTL. A longer session loses committed/reserved history off-chain and can over-authorize reservations, although the on-chain hook still enforces the physical cap.

Fix: derive expiry from session validity and rebuild from Postgres/on-chain spend.

### H-11: x402 replay claim is not atomic

Locations: `middleware/src/index.ts:97-101`, `x402GuardDbStore.ts:6-20`

`hasReplay` and `markReplay` are separate calls. Concurrent identical requests can both pass. The DB upsert does not report claim ownership.

Fix: expose one atomic `claimReplay(fingerprint, ttl): boolean`.

### H-12: Confirmed payment can omit x402 spend

Locations: `coinbase/apps/api/api.ts:903-950`

The payment is marked confirmed before x402 spend is committed. If spend persistence fails, payment remains confirmed while future budget checks omit it. The endpoint errors, but the durable financial state is already final.

Fix: reserve budget before payment and commit the same reservation after confirmation; reconciliation must repair incomplete commits.

## Medium

- Railguard remains an ERC-4337/7579-inspired direct-call prototype, not an integrated EntryPoint/module implementation.
- UserOp finalization endpoints still trust API-key callers rather than deriving status exclusively from chain evidence.
- SignGate evaluate still ignores `SaveIntent`, `SaveDecision`, and receipt persistence errors and can return a non-consumable decision.
- x402 `withSpendingPolicy` calls `toContext` twice; nondeterministic builders can evaluate one context and record another.
- Coinbase uses `defaultDevPolicy`, which does not set `allowedAssets` or `allowedNetworks`; support was added, but those restrictions are not active in this integration.
- x402 receipts remain process-local. Restart between evaluation and settlement loses receipt lookup and hash-chain continuity.
- Confirmation depth is hardcoded to one and no block hash is persisted for later reorg detection.
- `ExecutionBlocked` events are emitted before revert and therefore never survive on-chain.
- Session nonce lanes cannot be reused after expiry/revocation.
- The global SignGate API key remains a broad administrative capability without tenant/agent scopes.
- Coinbase migration state includes both `executed` and `confirmed`, increasing ambiguous terminal semantics.
- The “100 concurrent claimers” test exercises a toy in-memory lock, not the SQL update or API.
- No contract fuzz/invariant/reentrancy tests cover spend monotonicity, sequence behavior, and malicious token callbacks.

## CI and Verification

### railguard-new

- Foundry tests: 53/53 pass.
- On-chain PRD demo: pass.
- `forge fmt --check`: fail in hook and validator.
- Go tests and `go vet`: pass.
- SDK build/tests: 16/16 pass; npm audit clean.
- OPA: 3/3 pass.
- Canonical E2E: fail because the script still sends the old session-registration request and omits required `sessionKey`/`nonceKey`.

### x402-guard

- Build/typecheck: pass.
- TypeScript tests: 26/26 pass.
- Go tests and vet: pass.
- npm audit: clean.
- Example demo: pass.

### railguard-cdp

- Unit tests: 9/9 pass.
- Web production build: pass.
- Lint: fail with 28 diagnostics in the current dirty worktree.
- Encore typecheck: fail resolving local `@x402-guard/core` and middleware packages.
- `bun audit`: 43 advisories: 2 critical, 19 high, 17 moderate, 5 low.
- Video was removed from declared workspaces, but remains in the lockfile and audit graph.
- Existing modified/untracked user files were preserved.

## Pending 10x Work Without Scope Creep

### P0: Restore truthful green status

1. Fix format/lint/typecheck and update the canonical E2E request.
2. Regenerate the Coinbase lockfile after workspace isolation.
3. Upgrade Next.js, Remotion, CDP/Axios/form-data/ws dependency paths until deployable workspaces have no critical/high advisories.

Exit: all three CI workflows and canonical E2E pass from clean clones.

### P1: Create one atomic authorization primitive

Add `authorizePayment(context, policy): AuthorizationHandle` with atomic replay claim and budget reservation. Add `commit(handle, settlement)` and `release(handle, reason)`.

Use the same interface in x402 standalone and Coinbase Postgres. No new infrastructure.

Exit: 100 concurrent distinct payments cannot exceed a configured window; crash/retry tests preserve the cap.

### P2: Make decision facts immutable

Persist a canonical snapshot/hash containing all session/payment facts. Bind decision, approval, reservation, receipt, and execution ID to it. Remove mutable lookups behind old decisions.

Exit: changing any amount, cap, recipient, token, network, batch flag, validity, or policy version requires a new decision and approval.

### P3: Make chain evidence authoritative

Carry one `executionId` across payment intent, reservation, UserOp/direct execution, event, receipt, and tx. Add one reconciliation worker for CDP and harden the SignGate watcher with block hashes/reorg rollback.

Exit: every terminal state has chain evidence; every ambiguous state converges after restart; one event commits exactly one reservation.

### P4: Prove the state machines

Add real Postgres integration tests, property/invariant tests, and fault injection at:

- before/after replay claim;
- before/after budget reserve;
- before/after broadcast;
- before/after confirmation;
- before/after audit append;
- reorg and process restart.

Exit: executable invariants replace claims in remediation docs.

## Scope Fence

Do not add chains, tokens, paymasters, a full ERC-4337 migration, new UI modules, LLM features, Kafka, Kubernetes, governance, or microservices. The 10x gain comes from one immutable authorization identity, atomic budget reservation, deterministic recovery, and tests that prove those properties.
