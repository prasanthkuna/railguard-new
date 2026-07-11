# PRD: Railguard

## Product Name

**Railguard**

## One-Line Description

Railguard is a policy-enforced execution safety layer for AI-agent stablecoin payments, using ERC-7579 hooks, ERC-4337 nonce lanes, on-chain session spending caps, OPA policy decisions, EIP-712 signatures, and adversarial Foundry tests.

## Product Positioning

Railguard is not a consumer crypto product, wallet, exchange, custody service, trading bot, or DeFi app.

Railguard is an infrastructure primitive for teams building:

* AI-agent payments
* x402 stablecoin APIs
* embedded wallets
* account abstraction wallets
* paymaster systems
* custody transaction policies
* enterprise stablecoin payment flows
* programmable payment rails
* audit-ready financial automation

## Core Thesis

AI agents will increasingly initiate stablecoin payments through APIs, wallets, and programmatic payment rails. Off-chain policy engines can decide what should be allowed, but funds only remain safe if those policies are enforced at the on-chain execution boundary.

Railguard treats:

**Off-chain policy as advisory intelligence.**
**On-chain invariants as physical law.**

## Target User

### Primary User

Engineering teams building wallet/payment infrastructure.

Examples:

* Account abstraction engineers
* Stablecoin payment platform engineers
* Embedded wallet teams
* Paymaster/bundler infrastructure teams
* Custody policy engineers
* Developer platform engineers
* Security engineers working on transaction safety

### Secondary User

Compliance/risk teams that need deterministic payment evidence.

Examples:

* Crypto risk platforms
* AML/sanctions API providers
* Custody approval teams
* Institutional wallet platforms
* Audit and investigation teams

## Primary Goal

Build a public, open-source, technically serious proof-of-work that shows the user can design and implement regulated crypto infrastructure at Senior/Staff backend/platform level.

The product should help the creator get interviews from companies like:

* Coinbase CDP / Base / x402
* Stripe Bridge / Privy / Tempo
* Circle
* Fireblocks
* BitGo
* Anchorage
* Alchemy
* Safe
* ZeroDev
* Rhinestone
* Pimlico
* Biconomy
* OpenZeppelin
* Nethermind
* Chainalysis / TRM / Elliptic, with a different compliance-focused pitch

## Non-Goals

Railguard will not:

* custody real user funds
* operate an exchange
* offer trading signals
* support yield or staking
* support Indian consumer crypto payments
* claim legal compliance
* process real user deposits
* launch a token
* become a full wallet
* parse arbitrary DeFi router calldata in v1
* support every chain in v1
* build a large SaaS dashboard before the security primitive is proven
* claim generic ERC-7579 account compatibility in v1
* ship Paymaster in v1
* ship human approval workflows in v1

## V1 Scope (Frozen)

```text
RailguardAccountAdapter only
Base Sepolia + Anvil only
USDC ERC20 transfer(address,uint256) only
CALLTYPE_SINGLE and CALLTYPE_BATCH only
delegatecall rejected
unknown modes rejected
static allowed recipient, token, target
allowedTarget must equal token in v1
ALLOW / BLOCK only
no Paymaster in v1
no REQUIRE_APPROVAL in v1
no generic ERC-7579 compatibility claim
no Merkle roots in v1
```

## Core Product Promise

Railguard prevents an AI agent or automated workflow from moving stablecoin funds outside pre-approved physical limits.

It must block:

* wrong recipient
* wrong token
* wrong target contract
* wrong function selector
* transfer over per-payment limit
* transfer over session cumulative cap
* expired or not-yet-valid session
* replayed authorization
* delegatecall
* unknown execution mode
* arbitrary router/multicall bypass
* self-call account modification
* approval/transferFrom unless explicitly allowed
* batch transaction where one hidden leaf violates policy
* batch execution when allowBatch is false

## System Architecture

```text
AI Agent / x402 Client
        ↓
Railguard SDK / AgentKit Adapter
        ↓
Go SignGate
        ├─ OPA/Rego policy engine
        ├─ Redis/Postgres reservation ledger
        ├─ EIP-712 session authorization signer
        ├─ audit receipt signer
        ├─ policy decision API
        └─ mandatory UserOp watcher / reconciliation
        ↓
RailguardAccountAdapter (v1 only supported account)
        ├─ account-local sessions[account][nonceKey]
        ├─ Railguard Session Validator
        └─ Railguard Execution Hook
        ↓
ERC-4337 EntryPoint / Bundler / Base Sepolia
```

Paymaster is v1.1 only. It is not part of v1 MVP.

## Session Identity Model

### Nonce Lane

```text
UserOp.nonce = (uint192 nonceKey) << 64 | (uint64 sequence)
one active session per account + nonceKey
new permissions require new nonceKey
```

ERC-4337 treats nonce as a 192-bit key plus a 64-bit monotonically increasing sequence per key.

### Session ID

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
  block.chainid,
  railguardAccountAdapter,
  account,
  nonceKey,
  sessionConfigPhysicalHash
))
```

`policyHash` is audit metadata only. It is excluded from `sessionId`.

### Registration Authority

V1 session registration requires **both**:

1. Account-owner EIP-712 signature over `SessionAuthorization`
2. Railguard EIP-712 signature over the same struct

Rules:

```text
ownerSig proves account owner consent
railguardSig proves policy-approved session boundaries
sessionKey signature is valid for UserOp spend only, never registration
sessionKey cannot register or widen a session
```

### Budget Source of Truth

```text
On-chain session caps are source of truth for asset safety.
Off-chain reservations are advisory pre-checks and audit aids.
Direct UserOp submission with a valid sessionKey is allowed by design.
The hook remains the asset safety boundary.
Watcher reconciliation is mandatory in v1 to prevent off-chain drift.
```

## Core Modules

## 1. RailguardAccountAdapter

### Purpose

V1 account implementation. Stores approved payment sessions in account-local storage and orchestrates ERC-7579 execution with session context.

Each session is bound to:

* account
* nonce lane (`nonceKey`)
* session key
* token
* allowed target (must equal token in v1)
* allowed recipient
* allowed selector
* max per transfer
* max total session spend
* validity window
* batch permission
* policy hash (metadata)

### Storage

```solidity
mapping(address account => mapping(uint192 nonceKey => SessionConfig)) internal sessions;
```

No global session registry in v1.

### V1 APIs

```text
registerSession(config, ownerSig, railguardSig)
revokeSession(nonceKey)
executeWithSession(nonceKey, mode, executionCalldata)
```

### V1 Rule

Use static allowed fields, not Merkle roots.

Reason: static fields are easier to audit and harder to fake. Merkle allowlists can be added in v2 after the base module is secure.

## 2. Railguard Session Validator

### Purpose

Handles ERC-4337 validation-safe checks.

### Responsibilities

* Verify session key signature over UserOperation hash
* Verify nonce lane (`nonceKey`) matches session
* Verify session exists in account-local storage
* Verify temporal validity (`validAfter` / `validUntil`)
* Read account-associated session config only (ERC-7562 compatible)
* Return proper validation result

### Must Not Do

* Mutate temporary execution context
* Mutate cumulative spend
* Store active sessions during validation
* Perform deep calldata parsing
* Call external global policy registries
* Perform heavy business logic

## 3. Railguard Execution Hook

### Purpose

Acts as the physical on-chain enforcement boundary.

### Responsibilities

* Resolve session via adapter/account context (not transient validation storage)
* Parse ERC-7579 execution mode
* Allow only `CALLTYPE_SINGLE` and `CALLTYPE_BATCH`
* Reject delegatecall and unknown modes
* Decode single execution: `abi.encodePacked(target, value, callData)`
* Decode batch execution: `abi.encode(Execution[])`
* Inspect every leaf call
* Enforce v1 leaf rules:

```text
allowedTarget == token
target == allowedTarget
selector == ERC20.transfer(address,uint256)
recipient == session.allowedRecipient
amount <= session.maxPerTransfer
```

* Track cumulative session spend per `sessionId`
* Reject hidden malicious batch leaf
* Reject account self-call
* Reject arbitrary approval / transferFrom / permit / Permit2
* Reject native ETH transfer
* Reject batch when `allowBatch` is false
* Reject unknown router or nested multicall in v1

### ERC-7579 Hook Flow

The hook's `preCheck` receives `msgSender`, `value`, and `msgData`. It **returns** `hookData` passed to `postCheck`. External callers do not pass custom hookData directly.

```text
RailguardAccountAdapter.executeWithSession(nonceKey, mode, executionCalldata)
  → adapter resolves session = sessions[msg.sender][nonceKey]
  → adapter calls hook preCheck before execution
  → hook returns hookData = abi.encode(account, sessionId, nonceKey, executionDigest, frameSpend)
  → adapter executes ERC-7579 single/batch encoding
  → adapter calls hook postCheck with returned hookData
```

Generic ERC-7579 account compatibility is not claimed in v1.

### Execution Digest

```text
executionDigest = keccak256(abi.encode(
  block.chainid,
  address(this),
  account,
  sessionId,
  nonceKey,
  mode,
  keccak256(executionCalldata)
))
```

Mark `usedExecutions[account][executionDigest] = true` only after all leaves pass, frameSpend is computed, and cumulative spend check passes. Reverts must not consume the digest. ERC-4337 nonce sequence remains the primary UserOp replay guard.

### Critical Rule

The hook must enforce cumulative spend for both:

* CALLTYPE_SINGLE
* CALLTYPE_BATCH

Single-call execution must not bypass cumulative tracking.

## 4. Go SignGate

### Purpose

Off-chain policy, reservation, audit, and signing service. Not the ultimate asset-control layer.

### Responsibilities

* Receive payment intent
* Canonicalize intent
* Run OPA/Rego policy
* Check reservation ledger
* Generate EIP-712 session authorization
* Sign session authorization (Railguard co-signer)
* Generate audit receipt
* Run mandatory watcher reconciliation
* Return allow/block decision

### Decision Types (V1)

* ALLOW
* BLOCK

`REQUIRE_APPROVAL` is v1.1.

### Must Include

* idempotency key
* session ID
* policy hash
* intent hash
* risk result
* reason codes
* timestamp
* signer key ID
* audit receipt hash

## 5. OPA/Rego Policy Engine

### Purpose

Handles flexible business policy.

### Examples

* vendor allowlist
* domain allowlist
* amount threshold
* agent role
* daily policy limit
* risk API response
* environment restrictions
* PII metadata checks
* sanctions/risk score adapter mock

### Important Separation

OPA can reject more than Solidity.

Solidity must never accept something outside the physical safety floor.

## 6. Reservation Ledger

### Purpose

Tracks off-chain budget reservations and reconciliation state. Advisory relative to on-chain caps.

### Storage

* Redis for atomic fast-path reservation
* Postgres for durable source of truth

### State Machine

```text
INTENT_CREATED
→ POLICY_ALLOWED
→ SESSION_DRAFTED
→ BUDGET_RESERVED
→ SESSION_REGISTERED_ONCHAIN
→ ONCHAIN_ACTIVE
→ USEROP_SIGNED
→ USEROP_SUBMITTED
→ USEROP_INCLUDED
→ USEROP_FINALIZED
→ BUDGET_COMMITTED
```

### Failure States

```text
POLICY_DENIED
BUDGET_DENIED
REGISTRATION_FAILED
SIMULATION_FAILED
USEROP_REJECTED
USEROP_REVERTED
USEROP_REPLACED
RESERVATION_RELEASED
RECONCILIATION_REQUIRED
```

### Failure Rollback

```text
if on-chain registration fails → release reservation
if UserOp simulation fails → release reservation
if UserOp submitted → no TTL release
if finality uncertain → RECONCILIATION_REQUIRED
```

### Critical Rule

After `USEROP_SUBMITTED`, reservation must not be released by simple wall-clock TTL.

Release only through:

* explicit failed simulation
* bundler rejection
* UserOperation revert event
* confirmed replacement
* finality horizon reconciliation
* manual reconciliation path

## 7. Verifying Paymaster (V1.1 Only)

Not in v1 MVP.

### Important Clarification

Paymaster alone is not the asset safety boundary.

The Paymaster controls who gets sponsored gas.

The Execution Hook controls whether money can move.

## 8. Audit Receipt System

### Purpose

Creates deterministic evidence for every payment decision.

### Receipt Fields

```json
{
  "receiptVersion": "railguard.v1",
  "decisionId": "dec_...",
  "decision": "ALLOW",
  "reasonCodes": ["WITHIN_LIMITS"],
  "agentId": "agent_...",
  "intentHash": "0x...",
  "policyHash": "0x...",
  "sessionId": "0x...",
  "nonceKey": "12345",
  "chainId": 84532,
  "token": "0x...",
  "amountAtomic": "100000000",
  "recipient": "0x...",
  "allowBatch": false,
  "validUntil": 1760003600,
  "signerKeyId": "railguard-key-v1",
  "createdAt": "2026-07-08T00:00:00Z",
  "signature": "0x..."
}
```

### Signing

* EIP-712 for on-chain authorization
* secp256k1 for off-chain audit receipts in v1
* Signer key ID must be included
* Future v2 can use Ed25519, KMS, HSM, or TEE

## V1 Supported Execution

### Supported

* Base Sepolia + Anvil
* RailguardAccountAdapter only
* ERC-4337 account abstraction path
* ERC-7579 hook integration via adapter
* USDC test token transfer
* Single call
* Batch call where every leaf is independently safe and `allowBatch` is true
* Static recipient allowlist
* Static target allowlist (`allowedTarget == token`)
* Static selector allowlist
* Session cumulative cap
* Session per-transfer cap

### Rejected by Default

* delegatecall
* unknown execution modes
* arbitrary routers
* nested third-party multicall
* self-call account modification
* approve
* transferFrom
* permit / Permit2
* native ETH transfer
* arbitrary DeFi interactions
* live mainnet payments
* Indian consumer use case
* generic ERC-7579 accounts

## V1 Tech Stack

### Smart Contracts

* Solidity
* Foundry
* Anvil
* OpenZeppelin cryptography utilities
* ERC-4337 / ERC-7579 reference patterns via RailguardAccountAdapter
* Base Sepolia

### Backend

* Go
* OPA/Rego
* Redis
* Postgres
* Docker Compose

### SDK

* TypeScript
* AgentKit adapter stub
* x402-guard integration via `createX402Guard()` — see [x402-guard](https://github.com/prasanthkuna/x402-guard)
* Viem for test vectors

### Testing

* Foundry contract tests
* Anvil fork tests
* TypeScript EIP-712 test vectors
* CI threat matrix
* Differential OPA/EVM invariant tests

## Testing Strategy

### Contract Threat Tests

Must prove:

* single USDC transfer allowed
* single transfer over maxPerTransfer rejected
* single transfer to wrong recipient rejected
* single transfer increments cumulative session spend
* second single transfer exceeding maxTotalSpend rejected
* valid batch allowed when allowBatch is true
* batch rejected when allowBatch is false
* batch with one malicious leaf rejected
* batch aggregate exceeding cap rejected
* delegatecall rejected
* unknown mode rejected
* self-call rejected
* approve rejected
* transferFrom rejected
* expired session rejected
* not-yet-valid session rejected
* wrong nonce lane rejected
* replay rejected (nonce + executionDigest)
* mutated amount rejected
* mutated recipient rejected
* registration without ownerSig rejected
* registration without railguardSig rejected
* sessionKey cannot register session

## Differential Testing

### Purpose

Verify off-chain and on-chain safety agreement.

### Correct Rule

OPA may be stricter than Solidity.

Solidity must never be looser than the physical safety floor.

### Invariant Match Fields

* sessionKey
* token
* target
* recipient
* selector
* amount
* max per transfer
* max total spend
* validity window
* nonce lane
* call type
* batch aggregate total
* allowBatch

## Key Security Principles

### 1. No transient validation context

Do not write active session state during validation and expect execution hook to consume it later. Session config is durable and account-associated.

### 2. No Paymaster-only safety

Paymaster controls gas sponsorship, not asset movement. Paymaster is v1.1.

### 3. No arbitrary router parsing in v1

Unknown routers are denied by default.

### 4. Physical fields enforced; metadata labeled

Fields used for physical safety must be enforced on-chain. Metadata fields (e.g. `policyHash`) must be explicitly labeled as audit binding, not hook enforcement.

### 5. Static v1 over fancy v1

Use exact target/recipient/selector fields before Merkle roots. Force `allowedTarget == token` in v1.

### 6. Physical limits on-chain

Solidity must enforce irreversible constraints. On-chain session caps are asset truth.

### 7. Business policy off-chain

OPA can evaluate flexible rules, but cannot be the final asset safety boundary.

### 8. One adapter in v1

Do not claim generic ERC-7579 compatibility until adapter tests pass on a known account implementation.

## MVP Deliverables

### Contract Layer

* RailguardAccountAdapter with account-local session storage
* Session validator
* Execution hook
* Foundry tests
* Anvil threat tests

### Backend Layer

* Go SignGate
* OPA policy loader
* EIP-712 signing
* Redis reservation
* Postgres audit trail
* receipt generation
* mandatory watcher reconciliation

### SDK Layer

* TypeScript payment intent builder
* test vector generator
* AgentKit adapter stub; x402 via [x402-guard](https://github.com/prasanthkuna/x402-guard) `createX402Guard()`

### Documentation

* README
* THREAT_MODEL.md
* ARCHITECTURE.md
* SESSION_MODEL.md
* POLICY_MODEL.md
* RECEIPT_SCHEMA.md
* TEST_MATRIX.md
* HIRING_PITCH.md

## Demo Flow (Canonical E2E)

1. SignGate evaluates intent with OPA → ALLOW.
2. SignGate prepares session config draft in Postgres.
3. SignGate reserves budget pre-submit.
4. Account owner signs `SessionAuthorization`.
5. Railguard signs same `SessionAuthorization`.
6. `registerSession` writes account-local session on-chain.
7. Agent signs UserOp with sessionKey.
8. Account executes `executeWithSession(nonceKey, mode, executionCalldata)`.
9. Hook validates physical limits; payment succeeds.
10. Watcher ingests `ExecutionAllowed` / chain receipt.
11. Postgres reconciles committed spend; audit receipt generated.

Blocked attack demos:

1. AI agent attempts $50,000 transfer hidden inside batch → hook rejects malicious leaf.
2. Agent attempts wrong recipient → hook rejects before funds move.
3. Agent performs two valid transfers below maxPerTransfer but combined total exceeds maxTotalSpend → second transfer rejected.

## V1 Build Order

```text
1. Patch PRD/TRD (this document)
2. RailguardAccountAdapter + ERC-7579 single/batch execution encoding
3. Account-local session storage by account + nonceKey
4. ExecutionHook single spend
5. ExecutionHook batch spend + frame accumulator
6. SessionValidator
7. Dual-signature registration
8. Foundry threat matrix
9. TypeScript EIP-712 vectors
10. Go SignGate + OPA
11. Redis/Postgres + mandatory watcher reconciliation
```

## Success Metrics

### Engineering Metrics

* 100% threat tests passing
* CI badge green
* EIP-712 vectors match Solidity and TypeScript
* single and batch execution coverage
* all reject cases documented
* no known bypass through delegatecall, self-call, unknown router, or batch leaf
* clean Foundry gas report
* watcher reconciliation prevents off-chain drift

### Hiring Metrics

* GitHub repo gets serious technical review
* 10+ meaningful engineering replies
* 5+ interviews from crypto infra / wallet / stablecoin companies
* 1+ open-source contribution or issue discussion with AA ecosystem
* 1 technical blog shared by engineers in account abstraction or stablecoin infra

## Hiring Positioning

### Main Pitch

I built Railguard, an ERC-7579/ERC-4337 safety module for AI-agent stablecoin payments. It combines on-chain session spending limits, nonce-lane authorization, OPA/Rego policy decisions, deterministic audit receipts, and Anvil adversarial tests to prevent multicall bypasses, unsafe recipients, replay, and cumulative spend drift.

### Resume Bullet Version

* Built an ERC-7579 execution hook enforcing token, recipient, selector, per-transfer, and cumulative session caps for AI-agent stablecoin payments.
* Implemented ERC-4337 nonce-lane session authorization to isolate agent payment permissions and reduce hot-path gas overhead.
* Designed Go SignGate service for OPA/Rego policy evaluation, EIP-712 authorization signing, Redis/Postgres reservation tracking, and deterministic audit receipts.
* Created Anvil/Foundry adversarial test suite covering delegatecall rejection, batch injection, recipient mutation, replay, nonce-lane mismatch, and cumulative spend drift.
* Designed a dual-layer safety model separating off-chain business policy from on-chain physical asset constraints.

## Target Companies

### Best Fit

* Coinbase CDP / Base / AgentKit / x402
* Stripe Bridge / Privy / Tempo
* Circle
* Fireblocks
* BitGo
* Anchorage
* Alchemy
* Safe
* ZeroDev
* Rhinestone
* Pimlico
* Biconomy
* OpenZeppelin
* Nethermind
* Blockaid
* Hypernative

### Secondary Fit

* Mastercard BVNK
* Visa stablecoin teams
* PayPal PYUSD
* Paxos
* Kraken / Ink
* Gemini
* Ripple
* MoonPay
* QuickNode
* Helius
* Consensys / MetaMask / Infura
* Reown
* Turnkey
* Dfns
* Fordefi
* Dynamic

### Compliance-Focused Pitch

For Chainalysis, TRM Labs, Elliptic, Merkle Science, Sardine, Notabene, and Solidus Labs, pitch Railguard as:

A reference architecture for turning risk API outputs into deterministic payment decisions, signed audit receipts, and replayable compliance evidence.

## Final Product Definition

Railguard is a hiring-grade crypto infrastructure project proving that the builder understands:

* account abstraction
* stablecoin payment safety
* AI-agent transaction risk
* ERC-7579 modular accounts
* ERC-4337 nonce lanes
* on-chain invariant enforcement
* off-chain policy engines
* deterministic audit receipts
* threat modeling
* test-driven protocol safety
* backend reconciliation systems

## Final Principle

Railguard wins if a senior engineer at Coinbase, Circle, Fireblocks, Stripe, Alchemy, Safe, ZeroDev, or OpenZeppelin looks at the repo and says:

"This person does not just know Web3. This person understands how money-moving infrastructure fails."
