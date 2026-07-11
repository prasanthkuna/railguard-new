# Three-Project Security Audit

Date: 2026-07-11

Scope:

- `C:\Users\PrashanthKuna\railguard-new`
- `C:\Users\PrashanthKuna\x402-guard`
- `C:\Users\PrashanthKuna\coinbase`

This is a senior architecture and code review, not a formal third-party audit. The review prioritizes loss of funds, authorization bypass, replay/double execution, accounting divergence, cryptographic integrity, and fail-open behavior.

## Executive Verdict

The three repositories demonstrate a coherent idea: business policy before signature, bounded execution on-chain, and evidence after execution. They are strong hiring/demo artifacts, but they are not production-safe as a combined payment system yet.

The main systemic problem is that each layer has its own mutable state and identity model without one atomic source of truth. Coinbase owns invoice and execution state, x402-guard owns in-memory replay/spend state, SignGate owns Redis reservations and Postgres lifecycle state, and the hook owns final spend. Failures between those boundaries can create double execution, stale reservations, incorrect receipts, or records that say a transfer occurred when it did not.

## Critical Findings

### C-01: Concurrent Coinbase execution can pay twice

Locations: `coinbase/apps/api/api.ts:783-799`, `coinbase/apps/api/api.ts:835-895`

The claim update stores an idempotency key but leaves `status = 'prepared'`. Two concurrent requests using the same payment-intent ID and same idempotency key can both satisfy the update predicate and both call `executeCdpTransfer`.

Impact: duplicate on-chain payment.

Fix: introduce an `executing` state and atomically transition `prepared -> executing` once. Give the wallet provider a durable idempotency key, persist an execution attempt before broadcast, and reconcile by provider/chain transaction identity.

### C-02: A broadcast/DB split can also produce duplicate payment

Locations: `coinbase/apps/api/api.ts:835-916`

The external CDP transfer occurs before the database records success. If the transfer succeeds and the process or DB update fails, the catch path can mark the intent failed even though funds moved. Retrying through a new intent can pay again.

Impact: duplicate payment and false accounting.

Fix: use a durable payment state machine (`prepared -> executing -> submitted -> confirmed/failed/unknown`), provider idempotency, and reconciliation. Never classify an ambiguous post-broadcast failure as a definite failure.

### C-03: Live CDP credential errors silently become fake successful payments

Locations: `coinbase/apps/api/providers.ts:342-396`

Missing or malformed credentials return a deterministic demo hash. The API then marks the payment intent and invoice executed. This behavior is not constrained to an explicit demo environment.

Impact: the product can report payment success when no transaction exists.

Fix: require an explicit `PAYMENT_MODE=demo|live`; refuse startup if live credentials are absent; never fall back from live to demo after an execution error.

### C-04: SignGate cosigns sessions without proving a policy-approved decision

Locations: `railguard-new/signgate/internal/api/server.go:165-235`

Session registration checks only the global API key, structural fields, and equality with the current `policyHash`. It does not require an ALLOW decision, bind a decision/intent to the account and physical session limits, or verify caller ownership. Any API-key holder can request a Railguard signature over an arbitrary recipient, token, cap, and session key.

Impact: SignGate's signature does not prove the session was policy-approved, undermining the dual-signature security claim.

Fix: require a persisted, unconsumed ALLOW decision and derive the session constraints server-side from that decision. Atomically mark the authorization consumed and bind it to account, agent, chain, recipient, token, limits, validity, and nonce lane.

### C-05: x402-guard accepts negative payments and negative spend

Locations: `x402-guard/packages/policy/src/index.ts:17-25`, `x402-guard/packages/policy/src/index.ts:69-95`, `x402-guard/packages/middleware-go/guard.go:50-80`

Neither implementation requires `amountAtomic > 0`. A negative amount passes the per-call and window checks and can reduce accumulated spend. The review reproduced an `allow` decision for `-100` and a tracker balance of `-100`.

Impact: budget bypass for callers that can construct guard context directly; Go may also panic on a nil amount.

Fix: validate all context and configuration at construction/evaluation boundaries; reject nil, zero, negative, oversized, and malformed values.

## High Findings

### H-01: Permissionless hook initialization can be front-run

Locations: `railguard-new/contracts/src/RailguardExecutionHook.sol:40-47`, `railguard-new/contracts/script/Deploy.s.sol:20-25`

`setAdapter` is callable by anyone until first use. Deployment broadcasts hook creation, adapter creation, and initialization as separate transactions, allowing an observer to permanently bind the hook to an attacker-controlled address.

Fix: set the adapter immutably in the constructor, or restrict one-time initialization to an immutable deployer/factory and deploy atomically.

### H-02: Execution replay protection forbids legitimate repeated payments

Locations: `railguard-new/contracts/src/RailguardExecutionHook.sol:58-60`, `railguard-new/contracts/src/RailguardExecutionHook.sol:108-117`, `railguard-new/contracts/test/ReplayReject.t.sol:14-20`

The replay digest contains no sequence number. Two legitimate transfers with identical mode and calldata in the same session have the same digest, even if submitted under different ERC-4337 nonce sequences. The second is permanently rejected.

Fix: bind execution to the validated UserOperation hash or nonce sequence. Do not infer replay solely from payment calldata.

### H-03: The advertised ERC-4337/7579 path is not integrated

Locations: `railguard-new/contracts/src/RailguardAccountAdapter.sol:93-104`, `railguard-new/contracts/src/RailguardSessionValidator.sol:20-33`

The adapter is directly callable by the session-key EOA and has no EntryPoint `validateUserOp` integration. The validator is a standalone helper and the nonce lane does not participate in direct execution. This is a prototype modeled after those standards, not an ERC-4337 smart-account implementation.

Fix: describe it precisely as a prototype until integrated with a conforming account/module framework and EntryPoint validation/execution lifecycle.

### H-04: Session validation can revert on malformed signatures

Location: `railguard-new/contracts/src/RailguardSessionValidator.sol:31`

`ECDSA.recover` reverts for malformed signatures even though the function presents a boolean validation API. In account-abstraction simulation, malformed user input should normally produce validation failure rather than an unexpected revert.

Fix: use `ECDSA.tryRecover` and return false for all invalid signature forms.

### H-05: SignGate reservation totals can become permanently inflated

Locations: `railguard-new/signgate/internal/reservation/reservation.go:98-108`, `railguard-new/signgate/internal/reservation/reservation.go:118-165`

Reservation metadata expires after five minutes, but the aggregate `reserve:<session>` counter has no expiry. If a reservation is not finalized/released before metadata expires, its amount cannot be recovered and remains in the aggregate forever.

Fix: store reservations durably and calculate/repair totals transactionally, or use an atomic Redis script with an expiry index and a sweeper that can release expired amounts.

### H-06: Reservation and finalization APIs trust client-supplied authority

Locations: `railguard-new/signgate/internal/api/server.go:248-328`

The reserve endpoint trusts client-supplied `maxTotalSpend` rather than the registered session. Submission accepts arbitrary reservation/UserOp links. Finalization trusts caller-supplied status, tx hash, and block without verifying an EntryPoint receipt.

Impact: an API-key holder can corrupt budget/lifecycle state; physical on-chain limits remain the last defense.

Fix: load immutable session limits server-side, validate reservation ownership and transitions, and derive finalization from chain RPC/watcher evidence.

### H-07: Watcher reconciliation commits every pending reservation for a session

Locations: `railguard-new/signgate/internal/store/store.go:201-210`, `railguard-new/signgate/internal/store/store.go:240-246`

One `ExecutionAllowed` event marks all `BUDGET_RESERVED` and `USEROP_SUBMITTED` rows for the session committed. It does not match execution to a reservation, intent, amount, or UserOp.

Fix: include a unique execution/UserOp identifier in the on-chain event or maintain a provable mapping; reconcile one lifecycle item at a time.

### H-08: Receipt retrieval can invent an ALLOW decision

Location: `railguard-new/signgate/internal/store/store.go:153-169`

If the policy-decision lookup fails, `GetReceipt` defaults the decision to `ALLOW`. This can contradict the signed payload and stored evidence.

Fix: fail closed and return an integrity error; fetch receipt and decision in one relational query/transaction and verify consistency.

### H-09: x402 policy trusts a caller-supplied domain

Locations: `x402-guard/packages/core/src/index.ts:53-61`, `x402-guard/packages/policy/src/index.ts:73-83`

`evaluateAgentPolicy` checks `ctx.resource.domain`, not a domain derived from `ctx.resource.url`. A direct caller can provide `url=https://evil.example` with `domain=allowed.example`; the review reproduced an ALLOW decision.

Fix: accept a URL and method as the canonical input, parse/canonicalize internally, and reject inconsistent pre-parsed fields.

### H-10: x402 enforcement state is process-local and non-atomic

Locations: `x402-guard/packages/policy/src/index.ts:14-42`, `x402-guard/packages/middleware/src/index.ts:69-108`, `coinbase/apps/api/x402Guard.ts:6-21`

Replay and spend state lives in arrays/maps. Restarting or scaling to multiple instances resets/splits enforcement. Concurrent async evaluations can both observe budget headroom before either records spend.

Fix: define a storage interface and provide an atomic durable implementation using Redis/Postgres transactions or scripts. Keep in-memory storage explicitly test/dev-only.

### H-11: x402 settlement is attached to mutable `lastReceipt`

Locations: `x402-guard/packages/middleware/src/index.ts:120-125`, `coinbase/apps/api/x402Guard.ts:57-62`

Settlement does not accept a receipt/fingerprint ID. Concurrent payments in one organization can cause transaction A to settle transaction B's latest receipt; blocked receipts can also be settled.

Fix: return an immutable evaluation handle and settle by receipt ID after checking that it was allowed, unsettled, and matches the transaction payload.

### H-12: Coinbase x402 integration blocks every enabled payment

Locations: `coinbase/apps/api/x402Guard.ts:12-18`, `coinbase/apps/api/api.ts:805-815`

The policy is created for agent ID `org:<organizationID>`, but evaluation supplies `actor.userID`. The policy therefore emits `agent.mismatch` for normal requests.

Fix: define one agent identity contract and test the real API integration, not only package helpers.

### H-13: Payment claims can become permanently stuck before execution

Locations: `coinbase/apps/api/api.ts:783-833`

The idempotency key is claimed before invoice policy and x402 evaluation, outside the execution try/catch. A policy rejection/error leaves a prepared row with a claimed key. The same key then returns the prepared row as if idempotent, while another key is rejected.

Fix: perform deterministic validation before the claim, or model rejected/retryable states and make the whole transition transactional.

### H-14: Coinbase audit hash chain can fork under concurrency

Locations: `coinbase/apps/api/api.ts:1671-1705`

Appending reads the previous hash and inserts without a transaction or lock. Concurrent writers can use the same previous hash, creating multiple chain heads. The database also does not enforce append-only updates/deletes.

Fix: serialize per-organization appends with a locked head row/advisory lock, verify the chain, restrict DB privileges, and periodically anchor the head externally.

### H-15: WorkOS tokens without org context can select an org by header

Location: `coinbase/apps/api/auth.ts:23-39`

For a cryptographically valid token lacking `org_id`, the handler accepts `X-Organization-Id`. A user-level token could choose another tenant identifier unless the identity provider guarantees every accepted token has organization context.

Fix: require organization identity from verified claims/session membership and verify membership server-side; never trust a tenant header to fill a missing signed claim.

### H-16: Coinbase dependencies include exploitable advisories

Source: `bun audit` on 2026-07-11.

The current lockfile reports 43 advisories: 2 critical, 19 high, 17 moderate, and 5 low. Critical issues are in Remotion; high issues include Next.js, Axios/CDP transitive dependencies, form-data, and ws.

Fix: separate non-production video tooling from deployable workspaces, upgrade Next.js/Remotion/CDP dependency trees, rerun audit, and document any accepted transitive risk.

## Medium Findings

### M-01: On-chain spend can diverge from Redis spend

The hook allows direct session-key execution, while Redis only knows SignGate reservations. Watcher ingestion updates Postgres statuses but not Redis totals from `totalSpendAfter`. Future reservations can therefore be based on stale off-chain spend. On-chain caps prevent theft but availability and policy accounting diverge.

Locations: `RailguardAccountAdapter.sol:93-104`, `watcher.go:149-172`, `store.go:201-246`

### M-02: Confirmation handling processes immature blocks near genesis

At `watcher.go:106-112`, when `head <= confirmationDepth`, `safeHead` remains `head`; those blocks are processed without the requested confirmations. Reorged logs are never removed from storage.

### M-03: SignGate ignores persistence and reservation errors

Multiple handlers discard `Save*`, Redis commit/release, and status-update errors yet return success. Examples: `server.go:127-128`, `server.go:222-228`, `server.go:268`, `server.go:284-285`, `server.go:317-321`.

### M-04: One global API key controls all privileged SignGate actions

There is no per-agent/tenant authorization, scoped capability, rotation protocol, request signature, or rate limiting. A leaked key enables cosigning and lifecycle corruption across all accounts.

### M-05: Reentrant token execution can bypass pre/post accounting under unsafe configuration

The hook updates spend only after the token call. If a signed session uses a malicious token that can call the adapter as the configured session key/owner, nested execution can pass against stale spend. V1's trusted-USDC assumption reduces likelihood but the contract does not enforce a canonical token address.

Locations: `RailguardAccountAdapter.sol:101-103`, `RailguardExecutionHook.sol:63-95`

### M-06: Revoked or expired nonce lanes can never be reused

Any existing session permanently causes `SessionAlreadyExists`, even after revocation/expiry. Operationally, callers must continuously allocate new nonce keys.

Location: `RailguardAccountAdapter.sol:54-56`

### M-07: Block events are not observable on-chain

`ExecutionBlocked` is emitted immediately before a revert. Revert rolls back the event, so indexers cannot observe the advertised blocked event.

Locations: `RailguardExecutionHook.sol:65-66`, `RailguardExecutionHook.sol:133-157`, `RailguardExecutionHook.sol:167-201`

### M-08: x402 tracks authorization attempts, not successful settlement

Spend is recorded before the wrapped payment callback runs. A callback returning false or throwing still consumes budget. Conversely, settlement is not required to preserve an allowed spend entry.

Locations: `x402-guard/packages/middleware/src/index.ts:103-108`, `x402-guard/packages/middleware/src/index.ts:49-66`

### M-09: x402 does not enforce asset, network, HTTP method, or path

The context carries asset/network/resource data, but policy configuration and evaluation only enforce amount, agent, domain, payee, windows, and mandate. A payment on an unintended chain or asset can pass.

### M-10: x402 replay/spend structures grow without bounds

Spend records are never pruned and expired replay entries are not globally cleaned. Long-running processes can accumulate unbounded memory.

### M-11: Replay attempts and escalation errors violate “receipt every attempt”

Replay detection throws before receipt creation. An `onEscalate` exception also exits after consuming the replay fingerprint but before creating evidence.

Locations: `x402-guard/packages/middleware/src/index.ts:80-90`

### M-12: Go middleware is not feature-equivalent to TypeScript

The Go package omits domain/payee controls, replay protection, mandates, receipts, settlement, and rolling windows. Calling it a port can create false assurance.

Location: `x402-guard/packages/middleware-go/guard.go`

### M-13: Receipts are hash-linked but not independently trustworthy

The x402 ledger is in-memory, unsigned, unanchored, and has no verification API. An operator can truncate or recompute the entire chain. “Tamper-evident” is only valid if an earlier head is trusted externally.

Location: `x402-guard/packages/receipts/src/index.ts`

### M-14: Approvals are not bound to the policy run they approve

`ensurePayable` accepts the latest historical approved row for the invoice. It does not bind approval to a policy hash/run, amount, recipient, settings version, or invalidate approval after policy changes.

Locations: `coinbase/apps/api/api.ts:1493-1507`

### M-15: Separation of duties is optional in the API

Finance users may approve and execute the same invoice. If dual control is a security claim, the API does not enforce distinct actors or approver-only approval.

Locations: `coinbase/apps/api/api.ts:649-658`, `coinbase/apps/api/api.ts:745-755`

### M-16: Payment is marked executed at submission, not chain confirmation

`account.transfer` returns a transaction hash and the app immediately writes `executed`; there is no receipt status, confirmation depth, replacement, revert, or reorg reconciliation in this repo.

Locations: `coinbase/apps/api/providers.ts:370-384`, `coinbase/apps/api/api.ts:842-895`

### M-17: x402 receipt payer is factually wrong in Coinbase integration

The integration sets `payer` to the invoice wallet address, which is the recipient/payee, not the CDP account that sends funds. The resulting evidence is misleading.

Location: `coinbase/apps/api/api.ts:806-814`

### M-18: Demo transaction hashes can collide across distinct invoices

The demo hash seed contains organization, recipient, and amount but not invoice ID, payment-intent ID, chain, token, or execution idempotency key. Distinct payments with the same tuple produce the same fake tx hash.

Locations: `coinbase/apps/api/providers.ts:351-355`, `coinbase/apps/api/providers.ts:388-392`

## Low and Quality Findings

- `railguard-new/sdk/src/agentkitAdapter.ts:1-5` exports an adapter stub that always returns `ALLOW`. It should be removed from production exports or renamed conspicuously as unsafe demo code.
- `verifyReceiptSignature` throws on malformed signatures instead of consistently returning false (`sdk/src/eip712.ts:107-117`).
- Session and EIP-712 Go validation accepts malformed address strings and does not explicitly enforce uint192/uint48 ranges before conversion.
- Redis corrupt aggregate values are silently reset to zero in `reservation.go:89-92`, which is fail-open.
- `ReceiptLedger.settle` reuses a receipt ID for a second entry, making receipt identity ambiguous.
- Fingerprints use delimiter-joined unescaped fields, permitting collision/ambiguity with caller-controlled `|` characters.
- Coinbase `ensureIdempotencyKey` returns a trimmed key but callers ignore the return value, so validation and stored identity use different representations.
- Coinbase's document “safety scan” is a small substring denylist, not malware/content disarm scanning (`providers.ts:452-458`).
- Early Coinbase tables lack composite tenant foreign keys, so the database cannot prove referenced vendor/invoice rows belong to the same organization.
- Railguard contract coverage has no fuzz, invariant, reentrancy, or deployment-front-running tests.
- Coinbase has only eight package helper tests and no API auth, concurrency, state-machine, DB, x402 integration, or CDP failure tests.
- x402-guard has fourteen TypeScript tests; negative values, malformed context, concurrency, restart/multi-instance behavior, failed callbacks, and receipt-settlement binding are uncovered.

## Verification Results

### railguard-new

- Foundry format and tests: pass (quiet mode)
- Go tests and `go vet`: pass
- SDK build: pass
- SDK tests: 16/16 pass
- SDK npm audit: 0 vulnerabilities
- OPA: 3/3 pass
- Go race detector: not run because CGO is disabled in this Windows environment

### x402-guard

- TypeScript build and typecheck: pass
- TypeScript tests: 14/14 pass
- npm audit: 0 vulnerabilities
- Go tests and `go vet`: pass
- Go race detector: not run because CGO is disabled

### coinbase

- Unit tests: 8/8 pass
- Web production build: pass
- Lint: fail, 25 diagnostics in the current dirty worktree
- Encore/typecheck: fail because `@x402-guard/core` and `@x402-guard/middleware` cannot be resolved
- `bun audit`: fail, 43 advisories (2 critical, 19 high, 17 moderate, 5 low)
- The Coinbase worktree already contained unrelated modified/untracked files; this audit did not change them

## Fix Order Without Scope Creep

1. Make payment execution exactly-once/ambiguity-aware and remove live-to-demo fallback.
2. Bind SignGate cosigning to a persisted ALLOW decision and server-derived session constraints.
3. Fix x402 input validation, durable atomic state, and receipt-specific settlement; correct Coinbase agent identity.
4. Make hook initialization atomic and bind replay to UserOp nonce/hash.
5. Repair reservation expiry/reconciliation and fail on persistence errors.
6. Serialize and verify audit chains; bind approvals to immutable policy/payment facts.
7. Upgrade vulnerable dependencies and restore Coinbase lint/typecheck CI.
8. Add adversarial tests for every finding above before expanding features.
