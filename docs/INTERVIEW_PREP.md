# Railguard Interview Prep

> **Also read:** [THREE_PROJECT_IMPROVEMENTS_AND_INTERVIEW_PREP.md](./THREE_PROJECT_IMPROVEMENTS_AND_INTERVIEW_PREP.md) — detailed pass 3–5 improvements across railguard-new, x402-guard, and railguard-cdp, plus STAR stories and demo scripts.  
> **Architecture diagram:** [THREE_PROJECT_SYSTEM_DIAGRAM.md](./THREE_PROJECT_SYSTEM_DIAGRAM.md) — single master Mermaid diagram covering all three repos.

Use this as your spoken playbook. The goal is not to memorize every file. The goal is to understand the system deeply enough that any question maps back to one of the same few ideas:

1. AI agents can decide to pay, but chain execution is where money actually moves.
2. Off-chain policy is advisory intelligence.
3. On-chain invariants are physical law.
4. Deterministic receipts and watcher reconciliation make the off-chain world auditable.
5. The demo proves both the happy path and the attack paths.

## 1. Thirty-Second Pitch

Railguard is a policy-enforced execution safety layer for AI-agent stablecoin payments.

It combines ERC-4337 nonce-lane session authorization, ERC-7579-style execution hooks, a Go policy service called SignGate, OPA/Rego policy decisions, Redis/Postgres reservation and audit state, EIP-712 signatures, deterministic receipts, and adversarial Foundry tests.

The key design principle is simple:

```text
Off-chain policy decides what should happen.
On-chain hooks enforce what cannot be violated.
```

In v1, Railguard supports a deliberately narrow and auditable payment shape:

```text
Base Sepolia / Anvil
USDC transfer(address,uint256)
CALLTYPE_SINGLE and CALLTYPE_BATCH
one supported adapter account
owner + Railguard dual-signature session registration
ALLOW / BLOCK only
no Paymaster
no arbitrary router parsing
```

## 2. What Problem It Solves

AI agents and automated workflows will initiate payments through APIs, wallets, and stablecoin rails. An off-chain service can say "this looks allowed," but if the agent or client submits a transaction directly to chain, the money only stays safe if the smart contract blocks unsafe execution.

Railguard solves this by putting a hard boundary at execution time:

- The agent can request a payment.
- SignGate can evaluate policy and cosign a bounded session.
- The session key can only spend inside that box.
- The hook blocks anything outside the physical constraints.
- The watcher reconciles what actually happened on-chain back into the off-chain ledger.

This is why the project is infrastructure, not a wallet, exchange, or consumer app.

## 3. Architecture Mental Model

```text
AI Agent / x402 Client
  -> TypeScript SDK
  -> Go SignGate
       - OPA policy
       - Redis reservation
       - Postgres audit trail
       - EIP-712 session cosigner
       - receipt signer
       - watcher reconciliation
  -> RailguardAccountAdapter
       - account-local session storage
       - dual-signature registration
       - execution orchestration
  -> RailguardExecutionHook
       - physical transfer checks
       - spend commit
  -> ERC-4337 / EntryPoint / chain
```

### What Each Layer Owns

| Layer | Owns | Does Not Own |
| --- | --- | --- |
| SDK | intent construction, sessionId/EIP-712 helpers | asset safety |
| SignGate | policy, cosign, reservations, receipts, reconciliation | final on-chain enforcement |
| Adapter | session storage and execution orchestration | arbitrary wallet compatibility |
| Hook | token/recipient/selector/cap/batch enforcement | business policy or sanctions checks |
| Watcher | chain-to-DB reconciliation | deep reorg recovery in v1 |

Interview phrase:

> I separated policy intelligence from asset safety. OPA can be more restrictive, but the hook must never be looser than the physical payment floor.

## 4. Core Concepts

### ERC-4337

ERC-4337 account abstraction lets users submit `UserOperation`s instead of normal EOAs sending transactions directly. The important part for Railguard is the nonce model:

```text
UserOp.nonce = (uint192 nonceKey << 64) | uint64 sequence
```

The high 192 bits form a nonce lane. Railguard binds one active session to one account plus one nonce lane.

Why it matters:

- Each session has its own isolated lane.
- Replay protection comes from the ERC-4337 sequence.
- New permissions require a new nonceKey instead of mutating the old session.

Where:

- `docs/SESSION_MODEL.md`
- `contracts/src/RailguardSessionValidator.sol`
- `contracts/src/RailguardAccountAdapter.sol`

### ERC-7579-Style Hooks

Railguard uses an execution hook model:

```text
preCheck -> execute -> postCheck
```

The hook inspects the execution before money moves, then commits spend after the execution succeeds.

Why both phases exist:

- `preCheck` rejects unsafe calldata before execution.
- `postCheck` records spend and marks the execution digest used after the call path succeeds.

Where:

- `contracts/src/RailguardExecutionHook.sol`
- `contracts/src/libraries/ExecutionDecoder.sol`

### EIP-712

EIP-712 gives typed structured signatures. Railguard uses it for session registration.

Both the account owner and Railguard sign the same `SessionAuthorization` struct.

Why dual signatures:

- Owner signature proves the account owner consented.
- Railguard signature proves policy approved the exact boundaries.
- The session key can spend inside the approved session, but cannot register or widen a session.

Where:

- `contracts/src/RailguardAccountAdapter.sol`
- `signgate/internal/eip712/eip712.go`
- `sdk/src/eip712.ts`
- `contracts/test/Eip712Vector.t.sol`

### OPA/Rego

OPA is used for off-chain policy decisions such as risk, chain, domain, sanctions, and policy-specific allow/block rules.

Critical rule:

```text
OPA may reject more than Solidity.
Solidity must never allow outside the physical safety model.
```

Why:

- Business rules change faster than smart contracts.
- On-chain code should be small, deterministic, and asset-focused.
- Policy can evolve without redeploying the hook.

Where:

- `policy/railguard.rego`
- `policy/railguard_test.rego`
- `signgate/internal/policy`
- `fixtures/physical_vectors.json`

## 5. Session Identity

Railguard derives a deterministic `sessionId` from physical fields:

```text
sessionConfigPhysicalHash = keccak256(abi.encode(
  sessionKey,
  token,
  allowedTarget,
  allowedRecipient,
  allowedSelector,
  maxPerTransfer,
  maxTotalSpend,
  validAfter,
  validUntil,
  allowBatch
))

sessionId = keccak256(abi.encode(
  chainId,
  adapter,
  account,
  nonceKey,
  sessionConfigPhysicalHash
))
```

`policyHash` is excluded from `sessionId`.

Why:

- `sessionId` identifies the physical payment box.
- `policyHash` identifies which off-chain policy bundle approved it.
- Changing policy metadata should not change the physical session identity.
- Changing token, recipient, cap, selector, validity, or batch permission must change the session identity.

Where:

- `contracts/src/libraries/SessionId.sol`
- `signgate/internal/session/sessionid.go`
- `sdk/src/sessionId.ts`
- `contracts/test/SessionIdVector.t.sol`
- `signgate/internal/session/differential_test.go`
- `sdk/test/sessionId.test.ts`

## 6. The Physical Safety Box

A session defines exactly what the session key can do:

```text
account
nonceKey
sessionKey
token
allowedTarget
allowedRecipient
allowedSelector
maxPerTransfer
maxTotalSpend
validAfter
validUntil
allowBatch
policyHash metadata
```

In v1:

```text
allowedTarget == token
allowedSelector == ERC20 transfer(address,uint256)
```

The hook blocks:

- wrong recipient
- wrong token
- wrong target
- wrong selector
- amount over maxPerTransfer
- cumulative amount over maxTotalSpend
- expired or not-yet-valid session
- delegatecall
- unknown execution mode
- transferFrom / permit / approve-style bypasses
- batch injection where one hidden leaf violates policy
- batch execution when `allowBatch == false`
- execution digest replay

Where:

- `contracts/src/RailguardExecutionHook.sol`
- `contracts/test/ThreatMatrixGaps.t.sol`
- `contracts/test/PrdDemo.t.sol`
- `contracts/test/BatchSpend.t.sol`
- `contracts/test/CumulativeSpend.t.sol`
- `contracts/test/ReplayReject.t.sol`

## 7. Happy Path Flow

Use this sequence when asked to explain end to end:

1. Agent builds a payment intent through the SDK.
2. SignGate hashes the intent and evaluates OPA policy.
3. If OPA returns `ALLOW`, SignGate drafts a bounded session.
4. Account owner signs the EIP-712 session authorization.
5. Railguard signs the same EIP-712 authorization.
6. `registerSession` stores the session in adapter-local storage.
7. Session key signs a UserOp on its nonce lane.
8. Adapter calls hook `preCheck`.
9. Hook validates the execution leaves.
10. Adapter executes the ERC20 transfer.
11. Hook `postCheck` commits spend and marks digest used.
12. Watcher ingests `ExecutionAllowed`.
13. SignGate exposes receipt and reconciliation state.

Demo command:

```powershell
powershell -File .\scripts\e2e-happy-path.ps1
```

What this proves:

- contracts deploy
- SignGate uses real deployed addresses
- OPA allows the intent
- SignGate cosigns
- budget reservation works
- on-chain registration works
- transfer executes
- watcher ingests the event
- receipt can be fetched

## 8. Attack Demo Flow

Demo command:

```powershell
powershell -File .\scripts\demo-onchain.ps1
```

This is the strongest interview demo because it is fast and concrete:

```text
1 allowed USDC payment
3 blocked attacks:
  - wrong recipient / batch injection
  - transfer over per-payment limit
  - cumulative cap exceeded
```

Where:

- `contracts/test/PrdDemo.t.sol`
- `scripts/demo-onchain.ps1`

How to narrate:

> This demo is not just a unit test. It shows the product promise: the safe payment clears, and unsafe payment shapes revert before funds move.

## 9. SignGate Deep Dive

SignGate is the Go service that makes the system usable off-chain.

It owns:

- public intent evaluation
- protected session cosigning
- Redis reservation checks
- Postgres audit trail
- signed receipts
- watcher reconciliation

Key security choice:

Protected endpoints require `X-SignGate-API-Key`:

- `/v1/sessions/register`
- `/v1/reservations/reserve`
- `/v1/userops/submitted`
- `/v1/userops/finalized`
- `/v1/receipts/{decisionId}`
- `/v1/reconciliation/executions/{sessionId}`

Public endpoints:

- `/health`
- `/v1/intents/evaluate`

Where:

- `signgate/internal/api/server.go`
- `signgate/internal/api/auth.go`
- `signgate/internal/config/validate.go`
- `signgate/internal/reservation/reservation.go`
- `signgate/internal/receipt/receipt.go`

Interview phrase:

> I treat SignGate as policy and evidence infrastructure. It is important, but I do not trust it as the final asset boundary.

## 10. Receipts

Railguard receipts are deterministic audit evidence.

They include:

- decisionId
- ALLOW/BLOCK
- reason codes
- intentHash
- policyHash
- sessionId
- chain/token/recipient/amount fields
- signer key id
- createdAt
- ECDSA signature

Why receipts matter:

- Compliance and support teams need deterministic evidence.
- The SDK can verify payload hash parity and signature.
- The receipt ties off-chain policy to the session and intent.

Where:

- `docs/RECEIPT_SCHEMA.md`
- `signgate/internal/receipt/receipt.go`
- `sdk/src/eip712.ts`
- `sdk/test/receiptHash.test.ts`

## 11. Watcher and Reconciliation

The watcher closes the gap between "what SignGate expected" and "what chain executed."

Why it exists:

- A client can bypass SignGate after receiving a valid session key.
- Direct UserOp submission is allowed by design.
- The hook still enforces safety, but the off-chain ledger needs to catch up.

What it does:

- scans for `ExecutionAllowed`
- stores chain execution by sessionId
- commits budget based on actual execution
- marks stale submitted UserOps as `RECONCILIATION_REQUIRED`
- uses confirmation depth and rescan window

Known v1 limitation:

- confirmation depth and idempotent rescan exist
- deep reorg rewind is not implemented

Where:

- `signgate/internal/watcher/watcher.go`
- `signgate/internal/watcher/watcher_test.go`
- `signgate/internal/store/store.go`
- `db/migrations/002_watcher.sql`

Interview phrase:

> Reconciliation is mandatory because asset safety and accounting consistency are different problems. The hook protects funds; the watcher protects the off-chain truth.

## 12. Why Not Build More

When asked why no Paymaster, router support, dashboard, or mainnet:

Answer:

> I froze v1 around the security primitive. The hardest part is proving bounded execution, cross-language determinism, policy separation, and reconciliation. Paymaster, arbitrary routers, and dashboards are valuable, but they would expand the attack surface before the core invariant is proven.

Good non-goals to mention:

- no custody
- no exchange
- no token
- no Paymaster in v1
- no human approval workflow in v1
- no arbitrary DeFi router parsing
- no generic ERC-7579 compatibility claim
- no mainnet funds

## 13. Demo Checklist

Before an interview:

```powershell
# Contracts
cd contracts
forge test -vv
forge fmt --check
cd ..

# SignGate
cd signgate
go test ./...
go vet ./...
cd ..

# SDK
cd sdk
npm audit --audit-level=moderate
npm run build
npm test
cd ..

# OPA
powershell -File .\scripts\run-opa-tests.ps1

# Demo
powershell -File .\scripts\demo-onchain.ps1
powershell -File .\scripts\e2e-happy-path.ps1
```

If time is short in the interview, run:

```powershell
powershell -File .\scripts\demo-onchain.ps1
```

If they want full system proof, run:

```powershell
powershell -File .\scripts\e2e-happy-path.ps1
```

## 14. Code Walkthrough Route

Use this order when screen-sharing:

1. `docs/HIRING_PITCH.md`
   - establish the product in one minute
2. `docs/SECURITY_REVIEW.md`
   - show invariants and known non-goals
3. `contracts/src/RailguardAccountAdapter.sol`
   - show dual-signature registration and session storage
4. `contracts/src/RailguardExecutionHook.sol`
   - show physical enforcement
5. `contracts/test/PrdDemo.t.sol`
   - show allow plus block demos
6. `signgate/internal/api/server.go`
   - show API shape and protected routes
7. `policy/railguard.rego`
   - show off-chain policy rules
8. `signgate/internal/watcher/watcher.go`
   - show reconciliation
9. `sdk/src/sessionId.ts` and `signgate/internal/session/sessionid.go`
   - show cross-language deterministic session identity
10. `docs/TEST_MATRIX.md`
   - show test coverage

## 15. Senior-Level Design Tradeoffs

### Why static USDC transfer only?

Because the first version optimizes for provable asset safety. Arbitrary router calldata is hard to reason about because value movement can be indirect. v1 validates a simple physical shape: ERC20 `transfer(address,uint256)`.

### Why `allowedTarget == token`?

It prevents sending calldata to a proxy/router or malicious target while pretending the session is for a known token. In v1, the target contract and token must be the same.

### Why no global session registry?

The session lives in account-local adapter storage:

```solidity
mapping(address account => mapping(uint192 nonceKey => SessionConfig)) sessions;
```

This keeps validation account-scoped and avoids claiming broader compatibility than the project actually supports.

### Why is `policyHash` not in `sessionId`?

Because `sessionId` is the identity of the physical enforcement box. `policyHash` is audit metadata. If physical fields are unchanged, the on-chain safety box is unchanged.

### Why can direct UserOp submission be allowed?

Because the hook is the safety boundary. Even if the client bypasses SignGate after registration, the session key can only execute within the on-chain constraints. The watcher later reconciles off-chain state.

### Why have Redis reservations if the hook enforces caps?

Reservations improve UX and off-chain accounting by preventing obvious over-booking before submission. They are not trusted as asset safety. The hook remains final.

### Why differential tests?

Because this system has Solidity, Go, TypeScript, and Rego implementations of related ideas. Differential tests prevent silent drift in sessionId, EIP-712, receipt hashes, and policy physical vectors.

## 16. Common Interview Questions

### "Explain Railguard like I am a product leader."

Railguard lets AI agents make stablecoin payments only inside predefined limits. It gives teams a programmable safety layer: policy can decide whether an intent is allowed, but the smart contract prevents the actual token transfer from violating recipient, token, selector, timing, and spend caps.

### "Explain Railguard like I am a protocol engineer."

Railguard binds a session key to an ERC-4337 nonce lane and stores the session config in a v1 adapter account. Registration requires owner and Railguard EIP-712 signatures. Execution goes through a hook that decodes single or batch calls, validates every leaf against the session, rejects unsafe modes, and commits spend in postCheck.

### "What is the most important invariant?"

The hook must never allow a token movement outside the approved physical session constraints. OPA can be stricter, Redis can be wrong, and the client can bypass SignGate, but the hook must still block unsafe execution.

### "What happens if SignGate is compromised?"

If SignGate signs a malicious session, the account owner signature is still required for registration. If both owner and Railguard approve a bad session, the hook enforces exactly that bad but explicitly signed box. That is why SignGate key management would need HSM/MPC in production. In v1, the project demonstrates the protocol boundary, not production key custody.

### "What happens if Redis is wrong?"

Redis is advisory. The hook checks cumulative spend on-chain, so Redis cannot make the contract exceed `maxTotalSpend`.

### "What happens if Postgres is down?"

Audit and reconciliation degrade, but the on-chain hook remains the safety boundary. For production, I would make SignGate fail closed for cosigning if durable audit writes are unavailable.

### "What happens if the user submits directly to a bundler?"

That is allowed. The session key can only spend within the session. The watcher later detects `ExecutionAllowed` and reconciles the off-chain state.

### "What is the biggest v1 limitation?"

Deep reorg handling and production key management. The watcher has confirmation depth and rescan, but not a full chain rewind model. Signer keys are local/dev style, not HSM/MPC.

### "How would you improve it next without scope creep?"

I would harden the existing primitive before adding features:

1. Deep reorg-aware watcher state machine.
2. HSM/KMS-backed SignGate signer.
3. More property/fuzz tests around execution decoding and spend accounting.
4. CI E2E job against ephemeral Anvil.
5. Base Sepolia deployment runbook with verified addresses and explorer links.

I would not add dashboards, arbitrary routers, Paymaster, or approvals until the safety primitive is production-hardened.

## 17. Memory Hooks

Remember Railguard with this chain:

```text
Intent -> Policy -> Session -> Signature -> Hook -> Receipt -> Reconcile
```

Or:

```text
Decide off-chain.
Constrain on-chain.
Prove with receipts.
Reconcile with watcher.
```

Or the shortest possible version:

```text
OPA says yes.
EIP-712 signs the box.
The hook enforces the box.
The watcher proves what happened.
```

## 18. What To Say If You Get Stuck

Use this fallback:

> The central invariant is that the on-chain hook is the final safety boundary. Everything else exists either to decide, authorize, audit, or reconcile that boundary.

Then map the question:

- policy question -> OPA / SignGate
- authorization question -> EIP-712 / dual signatures
- replay question -> ERC-4337 nonce lane / executionDigest
- asset safety question -> hook
- audit question -> receipt / Postgres
- drift question -> watcher
- demo question -> `PrdDemo.t.sol` or `e2e-happy-path.ps1`

