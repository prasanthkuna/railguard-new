# TRD: Railguard

## 1. Product Summary

Railguard is a security-first infrastructure primitive for AI-agent stablecoin payments.

It combines:

* RailguardAccountAdapter (v1 only supported account)
* ERC-7579 execution hooks via adapter orchestration
* ERC-4337 nonce-lane session authorization
* on-chain physical payment constraints
* Go-based SignGate service
* OPA/Rego policy decisions
* Redis/Postgres reservation ledger
* EIP-712 signing
* deterministic audit receipts
* mandatory watcher reconciliation
* Foundry/Anvil adversarial tests

The core purpose is to prevent AI agents or automated workflows from moving stablecoin funds outside approved execution boundaries.

Railguard is not a wallet, exchange, custody platform, trading bot, token product, or consumer crypto app.

## 1.1 V1 Scope (Frozen)

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
no global session registry in v1
```

---

# 2. Design Principles

## 2.1 Physical Safety Over Policy Theater

Off-chain policy can advise.

On-chain constraints must enforce.

OPA may reject more than Solidity, but Solidity must never allow a payment outside the approved physical limits.

## 2.2 Deny Unknown Execution

V1 will not parse arbitrary routers, DeFi multicalls, Permit2, token approvals, transferFrom, native ETH transfers, or delegatecall.

Unknown execution paths are rejected by default.

## 2.3 Minimal Production Stack

Railguard uses boring, auditable components:

* Solidity
* Foundry
* Anvil
* Go
* OPA/Rego
* Redis
* Postgres
* TypeScript/Viem
* Docker Compose
* GitHub Actions

No Encore, NestJS, Kafka, Kubernetes, GraphQL, NATS, large dashboard, Paymaster, or approval workflow in v1.

## 2.4 No Transient Validation Context

The system must not write temporary "active session" storage during validation and expect execution hooks to consume it later.

Session constraints are registered and durable in account-local storage.

Execution hooks resolve session config via adapter/account context.

Validation reads account-associated session config only (ERC-7562 compatible).

## 2.5 Paymaster Is Not Asset Security (V1.1)

Paymaster is out of v1 scope.

When added in v1.1: Paymaster controls gas sponsorship. Execution Hook controls whether funds can move. Asset safety must never depend only on Paymaster approval.

## 2.6 Budget Source of Truth

```text
On-chain session caps are source of truth for asset safety.
Off-chain reservations are advisory pre-checks and audit aids.
Direct UserOp submission with a valid sessionKey is allowed by design.
The hook remains the asset safety boundary.
SignGate/Redis/Postgres are policy, reservation, and audit systems.
Watcher reconciliation is mandatory in v1 to prevent off-chain drift.
```

---

# 3. High-Level Architecture

```text
AI Agent / x402 Client
        |
        v
Railguard TypeScript SDK / AgentKit Adapter
        |
        v
Go SignGate API
        |-- OPA/Rego Policy Engine
        |-- Redis Reservation Ledger
        |-- Postgres Audit Store
        |-- EIP-712 Authorization Signer
        |-- Receipt Signer
        |-- Mandatory UserOp Watcher / Reconciliation
        |
        v
RailguardAccountAdapter (v1 only)
        |-- sessions[account][nonceKey] (account-local)
        |-- Railguard Session Validator
        |-- Railguard Execution Hook
        |
        v
ERC-4337 EntryPoint / Bundler
        |
        v
Base Sepolia / Anvil Fork
```

---

# 4. Repository Structure

```text
railguard/
  contracts/
    src/
      RailguardAccountAdapter.sol
      RailguardSessionValidator.sol
      RailguardExecutionHook.sol
      interfaces/
        IRailguardAccountAdapter.sol
        IRailguardSessionValidator.sol
        IRailguardExecutionHook.sol
      libraries/
        ExecutionDecoder.sol
        SessionTypes.sol
        SessionId.sol
        RailguardErrors.sol

    test/
      AccountAdapter.t.sol
      SessionRegistration.t.sol
      SingleCallSpend.t.sol
      BatchSpend.t.sol
      DelegatecallReject.t.sol
      MutationReject.t.sol
      ReplayReject.t.sol
      ExpiryReject.t.sol
      NonceLaneReject.t.sol
      CumulativeSpend.t.sol
      AllowBatchReject.t.sol

    script/
      Deploy.s.sol

    foundry.toml

  signgate/
    cmd/
      api/
        main.go

    internal/
      api/
      intent/
      eip712/
      policy/
      reservation/
      receipt/
      session/
      userop/
      watcher/
      store/
      config/
      logger/

    go.mod

  policy/
    railguard.rego
    railguard_test.rego

  sdk/
    package.json
    src/
      intent.ts
      eip712.ts
      sessionId.ts
      agentkitAdapter.ts
      x402Adapter.ts
    test/
      eip712Vectors.test.ts
      intentBuilder.test.ts
      sessionId.test.ts

  db/
    migrations/
      001_init.sql

  docs/
    PRD.md
    TRD.md
    ARCHITECTURE.md
    THREAT_MODEL.md
    SESSION_MODEL.md
    POLICY_MODEL.md
    RECEIPT_SCHEMA.md
    TEST_MATRIX.md
    HIRING_PITCH.md

  docker-compose.yml
  Makefile
  .github/
    workflows/
      ci.yml
```

Paymaster (`RailguardPaymaster.sol`) is v1.1 only and not in the v1 repo tree.

---

# 5. Runtime Services

## 5.1 Required Services

```text
signgate-api (includes mandatory watcher reconciliation loop)
postgres
redis
anvil
```

## 5.2 Optional Services

```text
pgadmin
redisinsight
```

These are dev-only and should not be part of core runtime assumptions.

---

# 6. Smart Contract Layer

## 6.1 Contract Goals

The contract layer enforces irreversible physical safety rules.

It must block:

* wrong recipient
* wrong token
* wrong target
* wrong selector
* amount above per-transfer cap
* cumulative spend above session cap
* expired or not-yet-valid session
* wrong nonce lane
* replayed execution
* delegatecall
* unknown execution modes
* self-call account modifications
* approvals
* transferFrom
* native ETH transfer
* hidden malicious batch leaf
* batch when allowBatch is false

## 6.2 Supported Chain

V1 supports:

```text
Base Sepolia
Anvil local fork
```

Mainnet is out of scope for v1.

## 6.3 Supported Asset

V1 supports:

```text
USDC-style ERC20 transfer(address,uint256)
```

Decimals should be handled off-chain.

On-chain logic works in atomic token units.

V1 invariant:

```text
allowedTarget == token
```

## 6.4 Supported Execution Types

Supported:

```text
CALLTYPE_SINGLE
CALLTYPE_BATCH
```

ERC-7579 encoding:

```text
single: abi.encodePacked(target, value, callData)
batch:  abi.encode(Execution[])
```

Rejected:

```text
CALLTYPE_DELEGATE
unknown custom modes
arbitrary routers
nested third-party multicall
```

## 6.5 Session Identity

### Nonce Lane

```text
UserOp.nonce = (uint192 nonceKey) << 64 | (uint64 sequence)
one active session per account + nonceKey
new permissions require new nonceKey
```

### Session ID Derivation

```solidity
bytes32 sessionConfigPhysicalHash = keccak256(abi.encode(
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
));

bytes32 sessionId = keccak256(abi.encode(
    block.chainid,
    railguardAccountAdapter,
    account,
    nonceKey,
    sessionConfigPhysicalHash
));
```

`policyHash` is audit metadata only. Excluded from `sessionId`.

Off-chain (SignGate, SDK, Postgres) must use the same derivation.

---

# 7. Contract: RailguardAccountAdapter

## 7.1 Purpose

V1 account implementation. Stores session config in account-local storage. Orchestrates ERC-7579 execution with session context. No global session registry in v1.

Generic ERC-7579 account compatibility is not claimed in v1.

## 7.2 Session Config

```solidity
struct SessionConfig {
    bytes32 sessionId;
    bytes32 policyHash;          // metadata only, not hook-enforced

    address account;
    address sessionKey;

    address token;
    address allowedTarget;
    address allowedRecipient;
    bytes4 allowedSelector;

    uint192 nonceKey;
    uint256 maxPerTransfer;
    uint256 maxTotalSpend;

    uint48 validAfter;
    uint48 validUntil;

    bool allowBatch;
    bool revoked;
}
```

## 7.3 Storage

```solidity
mapping(address account => mapping(uint192 nonceKey => SessionConfig)) internal sessions;
```

Validation reads `sessions[account][nonceKey]` where `account` is the validating smart account. This is account-associated storage compatible with ERC-7562 validation-scope rules.

## 7.4 Registration

```solidity
function registerSession(
    SessionConfig calldata config,
    bytes calldata ownerSig,
    bytes calldata railguardSig
) external;
```

A session can be registered only if:

* account is valid
* sessionKey is valid
* token is valid
* allowedTarget is valid
* allowedTarget == token (v1)
* allowedRecipient is valid
* allowedSelector == ERC20.transfer(address,uint256)
* maxPerTransfer > 0
* maxTotalSpend >= maxPerTransfer
* validUntil > validAfter
* ownerSig verifies over EIP-712 SessionAuthorization
* railguardSig verifies over the same SessionAuthorization struct
* sessionKey signature is never valid for registration
* nonceKey slot is unused (one active session per account + nonceKey)
* derived sessionId matches config

## 7.5 Update Rules

V1 does not allow widening an existing session.

No in-place update of recipient, target, token, maxPerTransfer, maxTotalSpend, validity window, or allowBatch.

To change permissions, create a new session with a new nonceKey.

## 7.6 Revocation

```solidity
function revokeSession(uint192 nonceKey) external;
```

Only account owner or approved account authority. Revoked sessions must fail validation and execution.

## 7.7 Execution Entry Point

```solidity
function executeWithSession(
    uint192 nonceKey,
    bytes32 mode,
    bytes calldata executionCalldata
) external;
```

Flow:

```text
1. session = sessions[msg.sender][nonceKey]
2. require session exists, not revoked, within validAfter/validUntil
3. derive sessionId from account + nonceKey + session config
4. call hook.preCheck(msg.sender, 0, executionCalldata)
5. hook returns hookData = abi.encode(account, sessionId, nonceKey, executionDigest, frameSpend)
6. execute ERC-7579 single or batch per mode
7. call hook.postCheck(hookData) for cleanup/verification
```

## 7.8 Events

```solidity
event SessionRegistered(
    address indexed account,
    bytes32 indexed sessionId,
    uint192 indexed nonceKey,
    address sessionKey,
    address token,
    address allowedRecipient,
    uint256 maxTotalSpend,
    uint48 validUntil,
    bytes32 policyHash
);

event SessionRevoked(
    address indexed account,
    bytes32 indexed sessionId,
    uint192 indexed nonceKey
);
```

---

# 8. Contract: RailguardSessionValidator

## 8.1 Purpose

Performs ERC-4337 validation-safe checks.

## 8.2 Responsibilities

* verify session exists in account-local storage
* verify session is not revoked
* verify validAfter <= now <= validUntil
* verify session key signature over UserOperation hash
* verify nonceKey extracted from UserOp.nonce matches session
* return validation success or failure

## 8.3 Must Not Do

* parse deep calldata
* mutate cumulative spend
* store temporary active context
* call external global policy registries
* execute complex business policy
* rely on transient session storage

## 8.4 Validation Inputs

```text
userOpHash
signature (sessionKey over userOpHash)
account
nonceKey (high 192 bits of UserOp.nonce)
```

## 8.5 Output

Return ERC-4337-compatible validation result.

Invalid signatures must not produce dangerous side effects.

---

# 9. Contract: RailguardExecutionHook

## 9.1 Purpose

Execution-phase safety boundary. Runs via adapter orchestration before and after execution.

## 9.2 ERC-7579 Hook Interface

ERC-7579 `preCheck(msgSender, value, msgData)` receives execution context. It **returns** `hookData` passed to `postCheck`. External callers do not pass custom hookData directly into the hook.

The adapter resolves session context and calls the hook. The hook does not independently discover `nonceKey` from thin air.

## 9.3 Responsibilities

* resolve session via adapter-local `sessions[account][nonceKey]`
* decode execution mode
* decode single call and batch calls
* inspect every leaf call
* enforce token/target/recipient/selector/amount constraints
* enforce allowBatch for batch mode
* enforce maxPerTransfer
* enforce maxTotalSpend
* increment cumulative session spend only after all checks pass
* reject unsafe execution paths

## 9.4 Storage

```solidity
mapping(address account => mapping(bytes32 sessionId => uint256 spent)) public sessionSpend;
mapping(address account => mapping(bytes32 executionDigest => bool used)) public usedExecutions;
```

## 9.5 Leaf Call Validation

Each leaf call must satisfy:

```text
allowedTarget == token
target == allowedTarget
value == 0
selector == ERC20.transfer(address,uint256)
recipient == session.allowedRecipient
amount <= session.maxPerTransfer
```

## 9.6 Frame Spend Tracking

```text
frameSpend = sum(all allowed ERC20 transfer amounts inside current execution frame)
sessionSpend[account][sessionId] + frameSpend <= maxTotalSpend
```

Only after all leaves pass:

```text
sessionSpend[account][sessionId] += frameSpend
usedExecutions[account][executionDigest] = true
```

If the frame reverts, `executionDigest` must not be consumed.

## 9.7 Execution Digest

```solidity
bytes32 executionDigest = keccak256(abi.encode(
    block.chainid,
    address(this),
    account,
    sessionId,
    nonceKey,
    mode,
    keccak256(executionCalldata)
));
```

ERC-4337 nonce sequence is the primary UserOp replay guard. `executionDigest` is defense-in-depth at the hook execution frame.

## 9.8 preCheck Return Value

```solidity
hookData = abi.encode(account, sessionId, nonceKey, executionDigest, frameSpend)
```

`postCheck` receives this returned hookData for cleanup/verification only.

## 9.9 Rejection Rules

Reject immediately if:

* call type is delegatecall
* mode is unknown
* batch mode and allowBatch is false
* target is zero address
* target is account itself
* allowedTarget != token
* target != allowedTarget
* native ETH value > 0
* selector is approve, transferFrom, permit, or Permit2
* selector is unknown
* recipient does not match session
* amount exceeds maxPerTransfer
* aggregate amount exceeds maxTotalSpend
* now < validAfter
* now > validUntil
* session revoked
* execution replayed (executionDigest already used)

## 9.10 Events

```solidity
event ExecutionAllowed(
    address indexed account,
    bytes32 indexed sessionId,
    uint192 indexed nonceKey,
    uint256 frameSpend,
    uint256 totalSpendAfter
);

event ExecutionBlocked(
    address indexed account,
    bytes32 indexed sessionId,
    string reason
);
```

---

# 10. Paymaster (V1.1 Only — Not in V1)

Deferred to v1.1:

* verify Railguard sponsorship signature
* reject expired sponsorship
* reject mutated UserOperation
* sponsor gas only for valid Railguard sessions

Not part of v1 build, tests, or Definition of Done.

---

# 11. Go SignGate Service

## 11.1 Purpose

Off-chain decision engine, signer, and mandatory reconciler. Not the ultimate asset-control layer.

## 11.2 Responsibilities

* receive payment intent
* canonicalize intent
* run OPA policy (ALLOW / BLOCK only in v1)
* reserve budget
* generate EIP-712 session authorization
* sign authorization (Railguard co-signer)
* produce audit receipt
* expose APIs
* persist state
* run mandatory watcher reconciliation

## 11.3 Package Structure

```text
signgate/internal/
  api/             HTTP handlers
  intent/          intent schema and canonicalization
  eip712/          typed data generation and signing
  policy/          OPA integration
  reservation/     Redis Lua reservation logic
  receipt/         audit receipt generation
  session/         session creation workflow
  userop/          UserOperation state models
  watcher/         EntryPoint event watcher (mandatory)
  store/           Postgres queries
  config/          env config
  logger/          structured logging
```

## 11.4 API Framework

Use Go standard `net/http` or `chi`.

Recommended:

```text
chi
pgx
go-redis
OPA Go SDK
go-ethereum
zerolog
```

No heavy framework.

---

# 12. Backend API

## 12.1 Health

```http
GET /health
```

Response:

```json
{
  "status": "ok"
}
```

## 12.2 Evaluate Intent

```http
POST /v1/intents/evaluate
```

Request:

```json
{
  "agentId": "agent_support_bot_1",
  "account": "0x...",
  "chainId": 84532,
  "token": "0x...",
  "recipient": "0x...",
  "amountAtomic": "100000000",
  "resource": {
    "method": "POST",
    "domain": "api.vendor.com",
    "path": "/v1/report"
  },
  "idempotencyKey": "idem_..."
}
```

Response:

```json
{
  "decision": "ALLOW",
  "decisionId": "dec_...",
  "intentHash": "0x...",
  "policyHash": "0x...",
  "reasonCodes": ["WITHIN_LIMITS"]
}
```

V1 decisions: `ALLOW` or `BLOCK` only.

## 12.3 Register Session

```http
POST /v1/sessions/register
```

Request:

```json
{
  "account": "0x...",
  "agentId": "agent_support_bot_1",
  "sessionKey": "0x...",
  "token": "0x...",
  "allowedTarget": "0x...",
  "allowedRecipient": "0x...",
  "allowedSelector": "0xa9059cbb",
  "nonceKey": "12345",
  "maxPerTransfer": "100000000",
  "maxTotalSpend": "500000000",
  "validAfter": 1760000000,
  "validUntil": 1760003600,
  "allowBatch": false,
  "policyHash": "0x..."
}
```

Response:

```json
{
  "sessionId": "0x...",
  "sessionConfigPhysicalHash": "0x...",
  "authorizationDigest": "0x...",
  "railguardSignature": "0x..."
}
```

`sessionId` must match on-chain derivation. `allowedTarget` must equal `token` in v1.

## 12.4 Reserve Budget

```http
POST /v1/reservations/reserve
```

Request:

```json
{
  "sessionId": "0x...",
  "agentId": "agent_support_bot_1",
  "intentHash": "0x...",
  "amountAtomic": "100000000",
  "idempotencyKey": "idem_..."
}
```

Response:

```json
{
  "reservationId": "res_...",
  "status": "RESERVED"
}
```

## 12.5 Mark UserOp Submitted

```http
POST /v1/userops/submitted
```

Request:

```json
{
  "reservationId": "res_...",
  "userOpHash": "0x...",
  "bundler": "pimlico",
  "submittedAt": "2026-07-08T00:00:00Z"
}
```

Response:

```json
{
  "status": "USEROP_SUBMITTED"
}
```

## 12.6 Mark UserOp Finalized

```http
POST /v1/userops/finalized
```

Request:

```json
{
  "userOpHash": "0x...",
  "txHash": "0x...",
  "blockNumber": 123456,
  "status": "SUCCESS"
}
```

Response:

```json
{
  "status": "BUDGET_COMMITTED"
}
```

Typically called by the mandatory watcher, not the client.

## 12.7 Get Receipt

```http
GET /v1/receipts/{decisionId}
```

Response:

```json
{
  "decisionId": "dec_...",
  "decision": "ALLOW",
  "receiptHash": "0x...",
  "signature": "0x..."
}
```

---

# 13. OPA/Rego Policy

## 13.1 Purpose

Flexible off-chain policy decisions.

## 13.2 Policy Inputs

```json
{
  "agentId": "agent_support_bot_1",
  "account": "0x...",
  "chainId": 84532,
  "token": "0x...",
  "recipient": "0x...",
  "amountAtomic": "100000000",
  "resource": {
    "method": "POST",
    "domain": "api.vendor.com",
    "path": "/v1/report"
  },
  "risk": {
    "recipientRiskScore": 10,
    "sanctionsHit": false
  },
  "limits": {
    "maxPerTransfer": "100000000",
    "maxTotalSpend": "500000000"
  }
}
```

## 13.3 Policy Output

```json
{
  "decision": "ALLOW",
  "reasonCodes": ["WITHIN_LIMITS"]
}
```

## 13.4 Required Decisions (V1)

```text
ALLOW
BLOCK
```

`REQUIRE_APPROVAL` is v1.1.

## 13.5 Required Policies

* block sanctioned recipient
* block high-risk recipient
* block unknown domain
* block over-limit amount (OPA may be stricter than on-chain)
* allow known vendor under limit
* block wrong chain
* block unsupported token
* block allowedTarget != token in v1

---

# 14. Reservation Ledger

## 14.1 Redis Purpose

Fast atomic budget reservation. Advisory relative to on-chain caps.

## 14.2 Postgres Purpose

Durable audit and reconciliation source of truth.

## 14.3 Reservation State Machine

```text
INTENT_CREATED
POLICY_ALLOWED
SESSION_DRAFTED
BUDGET_RESERVED
SESSION_REGISTERED_ONCHAIN
ONCHAIN_ACTIVE
USEROP_SIGNED
USEROP_SUBMITTED
USEROP_INCLUDED
USEROP_FINALIZED
BUDGET_COMMITTED
```

## 14.4 Failure States

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

## 14.5 Failure Rollback

```text
if on-chain registration fails → release reservation
if UserOp simulation fails → release reservation
if UserOp submitted → no TTL release
if finality uncertain → RECONCILIATION_REQUIRED
```

## 14.6 Critical Rule

After `USEROP_SUBMITTED`, do not release budget by TTL alone.

Release only through evidence:

* failed simulation
* bundler rejection
* reverted UserOp event
* replacement detected
* finality horizon reconciliation
* manual reconciliation

---

# 15. Redis Lua Reservation

## 15.1 Inputs

```text
sessionId
agentId
intentHash
amountAtomic
maxTotalSpend
idempotencyKey
preSubmitTTL
```

## 15.2 Logic

```text
if idempotencyKey already exists:
    return existing reservation

currentReserved = get reserved amount for session
if currentReserved + amountAtomic > maxTotalSpend:
    return BUDGET_DENIED

create reservation
increment reserved amount
set TTL only for pre-submit state
return RESERVED
```

## 15.3 Post-Submit Rule

Once UserOp is submitted:

```text
remove pre-submit TTL release behavior
freeze reservation until reconciliation evidence
```

---

# 16. Postgres Schema

## 16.1 sessions

```sql
CREATE TABLE sessions (
    id UUID PRIMARY KEY,
    session_id TEXT UNIQUE NOT NULL,
    account TEXT NOT NULL,
    agent_id TEXT NOT NULL,
    session_key TEXT NOT NULL,
    token TEXT NOT NULL,
    allowed_target TEXT NOT NULL,
    allowed_recipient TEXT NOT NULL,
    allowed_selector TEXT NOT NULL,
    nonce_key TEXT NOT NULL,
    max_per_transfer NUMERIC(78,0) NOT NULL,
    max_total_spend NUMERIC(78,0) NOT NULL,
    valid_after BIGINT NOT NULL,
    valid_until BIGINT NOT NULL,
    allow_batch BOOLEAN NOT NULL DEFAULT false,
    policy_hash TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at TIMESTAMPTZ,
    UNIQUE (account, nonce_key)
);
```

## 16.2 payment_intents

```sql
CREATE TABLE payment_intents (
    id UUID PRIMARY KEY,
    intent_hash TEXT UNIQUE NOT NULL,
    agent_id TEXT NOT NULL,
    account TEXT NOT NULL,
    chain_id BIGINT NOT NULL,
    token TEXT NOT NULL,
    recipient TEXT NOT NULL,
    amount_atomic NUMERIC(78,0) NOT NULL,
    resource_domain TEXT,
    resource_path TEXT,
    idempotency_key TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

## 16.3 policy_decisions

```sql
CREATE TABLE policy_decisions (
    id UUID PRIMARY KEY,
    decision_id TEXT UNIQUE NOT NULL,
    intent_hash TEXT NOT NULL,
    decision TEXT NOT NULL CHECK (decision IN ('ALLOW', 'BLOCK')),
    reason_codes JSONB NOT NULL,
    policy_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

## 16.4 budget_reservations

```sql
CREATE TABLE budget_reservations (
    id UUID PRIMARY KEY,
    reservation_id TEXT UNIQUE NOT NULL,
    session_id TEXT NOT NULL,
    intent_hash TEXT NOT NULL,
    agent_id TEXT NOT NULL,
    amount_atomic NUMERIC(78,0) NOT NULL,
    status TEXT NOT NULL,
    idempotency_key TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    submitted_at TIMESTAMPTZ,
    finalized_at TIMESTAMPTZ
);
```

## 16.5 userop_lifecycle

```sql
CREATE TABLE userop_lifecycle (
    id UUID PRIMARY KEY,
    userop_hash TEXT UNIQUE NOT NULL,
    reservation_id TEXT NOT NULL,
    session_id TEXT NOT NULL,
    status TEXT NOT NULL,
    bundler TEXT,
    tx_hash TEXT,
    block_number BIGINT,
    submitted_at TIMESTAMPTZ,
    included_at TIMESTAMPTZ,
    finalized_at TIMESTAMPTZ,
    last_checked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

## 16.6 audit_receipts

```sql
CREATE TABLE audit_receipts (
    id UUID PRIMARY KEY,
    decision_id TEXT UNIQUE NOT NULL,
    intent_hash TEXT NOT NULL,
    session_id TEXT,
    receipt_hash TEXT NOT NULL,
    receipt_json JSONB NOT NULL,
    signature TEXT NOT NULL,
    signer_key_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

---

# 17. EIP-712 Session Authorization

## 17.1 Domain

```text
name: Railguard
version: 1
chainId: 84532
verifyingContract: RailguardAccountAdapter
```

## 17.2 Type

```text
SessionAuthorization(
  address account,
  uint192 nonceKey,
  address sessionKey,
  address token,
  address allowedTarget,
  address allowedRecipient,
  bytes4 allowedSelector,
  uint256 maxPerTransfer,
  uint256 maxTotalSpend,
  uint48 validAfter,
  uint48 validUntil,
  bool allowBatch,
  bytes32 policyHash
)
```

Both account owner and Railguard sign the same struct. `sessionId` is derived off-chain and on-chain from physical fields; it is not a separate signed field.

## 17.3 Required Test

TypeScript/Viem generated digest must equal Solidity generated digest.

SessionId derivation test must pass across Solidity, TypeScript, and Go.

---

# 18. Audit Receipt

## 18.1 Purpose

Off-chain non-repudiable evidence. `policyHash` binds which off-chain policy bundle authorized the session.

## 18.2 Receipt Shape

```json
{
  "receiptVersion": "railguard.v1",
  "decisionId": "dec_...",
  "decision": "ALLOW",
  "reasonCodes": ["WITHIN_LIMITS"],
  "agentId": "agent_support_bot_1",
  "intentHash": "0x...",
  "policyHash": "0x...",
  "sessionId": "0x...",
  "nonceKey": "12345",
  "chainId": 84532,
  "token": "0x...",
  "recipient": "0x...",
  "amountAtomic": "100000000",
  "allowBatch": false,
  "validUntil": 1760003600,
  "signerKeyId": "railguard-key-v1",
  "createdAt": "2026-07-08T00:00:00Z",
  "signature": "0x..."
}
```

## 18.3 Signing

V1 uses secp256k1.

Future version may support Ed25519, KMS, HSM, TEE attestation.

---

# 19. TypeScript SDK

## 19.1 Purpose

Developer-facing integration layer.

## 19.2 Responsibilities

* build payment intent
* derive sessionId (must match Solidity)
* generate EIP-712 test vectors
* integrate with Viem
* provide AgentKit adapter stub
* re-export [x402-guard](https://github.com/prasanthkuna/x402-guard) via `createX402Guard()` (`sdk/src/x402Adapter.ts`)

## 19.3 V1 SDK APIs

```typescript
buildPaymentIntent(input)
deriveSessionId(input)
buildSessionAuthorization(input)
signSessionKeyUserOp(input)
verifyReceipt(input)
```

## 19.4 V1 Non-Goal

Do not build a full wallet SDK.

---

# 20. UserOp Watcher (Mandatory in V1)

## 20.1 Purpose

Reconciles submitted UserOperations. Prevents off-chain drift when direct UserOp submission bypasses SignGate.

## 20.2 Responsibilities

* watch EntryPoint events
* ingest ExecutionAllowed / ExecutionBlocked events from hook
* track userOpHash
* map userOpHash to reservation
* mark included
* mark finalized
* mark reverted
* trigger budget commit
* trigger reservation release only with evidence
* mark uncertain cases as RECONCILIATION_REQUIRED
* update Postgres committed spend from on-chain truth

## 20.3 Deployment

Runs inside signgate-api process in v1 (background reconciliation loop). Not optional.

## 20.4 Inputs

```text
EntryPoint address
chain RPC URL
RailguardAccountAdapter address
RailguardExecutionHook address
userOpHash
reservationId
confirmation depth
```

## 20.5 Output States

```text
USEROP_INCLUDED
USEROP_FINALIZED
USEROP_REVERTED
RECONCILIATION_REQUIRED
```

---

# 21. Foundry Test Matrix

## 21.1 Account Adapter / Registration Tests

```text
test_register_valid_session_dual_sig
test_reject_registration_without_owner_sig
test_reject_registration_without_railguard_sig
test_reject_session_key_registering_session
test_reject_zero_account
test_reject_zero_session_key
test_reject_zero_token
test_reject_allowed_target_not_equal_token
test_reject_invalid_validity_window
test_reject_max_total_below_max_per_transfer
test_reject_duplicate_nonce_key
test_revoke_session
test_reject_revoked_session
test_session_id_derivation_matches_offchain
```

## 21.2 Single Call Tests

```text
test_single_transfer_allowed
test_single_transfer_wrong_recipient_reverts
test_single_transfer_wrong_token_reverts
test_single_transfer_wrong_target_reverts
test_single_transfer_wrong_selector_reverts
test_single_transfer_over_max_per_transfer_reverts
test_single_transfer_updates_cumulative_spend
test_second_single_transfer_exceeding_session_cap_reverts
```

## 21.3 Batch Tests

```text
test_batch_all_valid_allowed
test_batch_one_bad_leaf_reverts
test_batch_aggregate_exceeding_session_cap_reverts
test_batch_wrong_recipient_reverts
test_batch_wrong_token_reverts
test_batch_over_max_per_transfer_reverts
test_batch_rejected_when_allow_batch_false
```

## 21.4 Execution Mode Tests

```text
test_delegatecall_reverts
test_unknown_mode_reverts
test_self_call_reverts
test_native_eth_transfer_reverts
test_approve_reverts
test_transfer_from_reverts
test_permit_reverts
```

## 21.5 Replay and Expiry Tests

```text
test_expired_session_reverts
test_not_yet_valid_session_reverts
test_replayed_execution_digest_reverts
test_wrong_nonce_lane_reverts
```

## 21.6 Mutation Tests

```text
test_mutated_amount_reverts
test_mutated_recipient_reverts
test_mutated_target_reverts
test_mutated_selector_reverts
```

---

# 22. Differential Test Strategy

## 22.1 Purpose

Ensure off-chain and on-chain models agree on physical safety invariants.

## 22.2 Rule

OPA can be stricter than Solidity.

Solidity must never be looser than the physical safety floor.

## 22.3 Compared Fields

```text
sessionKey
token
target
recipient
selector
amount
maxPerTransfer
maxTotalSpend
validAfter
validUntil
nonceKey
callType
batchAggregate
allowBatch
```

## 22.4 CI Failure Condition

Build fails if:

```text
on-chain hook allows an execution that violates the physical invariant model
```

---

# 23. GitHub Actions CI

## 23.1 Jobs

```text
contracts
go-tests
opa-tests
typescript-tests
differential-tests
```

## 23.2 contracts

```text
forge fmt --check
forge build
forge test -vvv
forge snapshot
```

## 23.3 go-tests

```text
go test ./...
go vet ./...
```

## 23.4 opa-tests

```text
opa test policy/
```

## 23.5 typescript-tests

```text
npm ci
npm test
```

## 23.6 differential-tests

```text
start anvil
deploy RailguardAccountAdapter
run TS sessionId + EIP-712 vectors
run Go/OPA decisions
compare against EVM results
```

---

# 24. Docker Compose

## 24.1 Services

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: railguard
      POSTGRES_PASSWORD: railguard
      POSTGRES_DB: railguard
    ports:
      - "5432:5432"

  redis:
    image: redis:7
    ports:
      - "6379:6379"

  anvil:
    image: ghcr.io/foundry-rs/foundry:latest
    command: anvil --host 0.0.0.0
    ports:
      - "8545:8545"

  signgate:
    build:
      context: ./signgate
    depends_on:
      - postgres
      - redis
      - anvil
    ports:
      - "8080:8080"
```

---

# 25. Environment Variables

```text
APP_ENV=local
HTTP_PORT=8080

POSTGRES_URL=postgres://railguard:railguard@localhost:5432/railguard?sslmode=disable
REDIS_ADDR=localhost:6379

CHAIN_ID=84532
RPC_URL=http://localhost:8545
ENTRYPOINT_ADDRESS=0x...
ADAPTER_ADDRESS=0x...
HOOK_ADDRESS=0x...

RAILGUARD_SIGNER_PRIVATE_KEY=...
RECEIPT_SIGNER_PRIVATE_KEY=...
SIGNER_KEY_ID=railguard-key-v1

OPA_POLICY_PATH=../policy/railguard.rego

WATCHER_ENABLED=true
WATCHER_CONFIRMATION_DEPTH=12
```

---

# 26. Security Requirements

## 26.1 Required

* no private keys committed
* deterministic EIP-712 hashing
* deterministic sessionId derivation across Solidity, TypeScript, Go
* explicit field-by-field struct hashing
* lower-s signature protection via standard libraries
* no raw ecrecover in custom code
* replay protection (nonce sequence + executionDigest)
* cumulative spend tracking
* no transient validation context
* account-local session storage only in v1
* no arbitrary router parsing
* no delegatecall
* no native ETH transfer
* no approvals in v1
* no mainnet deployment in v1
* dual-signature registration (owner + Railguard)
* mandatory watcher reconciliation

## 26.2 Threats Covered

* hidden malicious batch leaf
* recipient mutation
* amount mutation
* wrong token
* wrong target
* wrong selector
* session replay
* expired / not-yet-valid session
* nonce lane mismatch
* cumulative spend drift
* delegatecall bypass
* post-submit TTL release bug
* off-chain drift via direct UserOp bypass
* unauthorized session registration

## 26.3 Threats Not Covered in V1

* full MPC/TSS
* HSM compromise
* TEE attestation
* arbitrary DeFi router safety
* cross-chain settlement
* Solana execution
* production sanctions screening
* live mainnet funds
* formal verification
* Paymaster bypass (Paymaster not in v1)
* generic ERC-7579 account compatibility

---

# 27. Observability

## 27.1 Logs

Use structured JSON logs.

Fields:

```text
requestId
decisionId
intentHash
sessionId
nonceKey
agentId
account
decision
reasonCodes
latencyMs
```

## 27.2 Metrics

V1 can expose simple `/metrics` later.

Initial metrics:

```text
intent_evaluations_total
policy_denied_total
budget_denied_total
sessions_registered_total
userops_submitted_total
userops_finalized_total
reservations_reconciliation_required_total
watcher_reconciliation_lag_seconds
```

---

# 28. Development Commands

```bash
make setup
make contracts-build
make contracts-test
make signgate-test
make opa-test
make sdk-test
make ci
make dev
```

---

# 29. E2E Happy Path

```text
1. SignGate evaluates intent with OPA → ALLOW
2. SignGate prepares session config draft in Postgres (SESSION_DRAFTED)
3. SignGate reserves budget pre-submit (BUDGET_RESERVED)
4. Account owner signs SessionAuthorization (EIP-712)
5. Railguard signs same SessionAuthorization
6. registerSession writes account-local session on-chain (SESSION_REGISTERED_ONCHAIN → ONCHAIN_ACTIVE)
7. Agent signs UserOp with sessionKey
8. Account executes executeWithSession(nonceKey, mode, executionCalldata)
9. Hook preCheck validates physical limits; execution proceeds; postCheck verifies
10. Watcher ingests ExecutionAllowed / chain receipt
11. Postgres reconciles committed spend (BUDGET_COMMITTED)
```

Failure rollback:

```text
registration fails → release reservation
simulation fails → release reservation
UserOp submitted → no TTL release
finality uncertain → RECONCILIATION_REQUIRED
```

---

# 30. V1 Build Order

```text
1. Patch PRD/TRD
2. RailguardAccountAdapter + ERC-7579 single/batch execution encoding
3. Account-local session storage by account + nonceKey
4. ExecutionHook single spend
5. ExecutionHook batch spend + frame accumulator
6. SessionValidator
7. Dual-signature registration
8. Foundry threat matrix
9. TypeScript EIP-712 + sessionId vectors
10. Go SignGate + OPA
11. Redis/Postgres + mandatory watcher reconciliation
```

---

# 31. Definition of Done

Railguard v1 is complete when:

* contracts compile
* all Foundry tests pass
* RailguardAccountAdapter stores sessions account-locally
* dual-signature registration enforced
* sessionId derivation matches across Solidity, TypeScript, Go
* single and batch call safety is enforced
* allowBatch enforced
* allowedTarget == token enforced
* cumulative spend works for single and batch
* delegatecall is rejected
* unknown modes are rejected
* bad recipient is rejected
* over-limit transfer is rejected
* expired and not-yet-valid sessions are rejected
* replay is rejected (nonce + executionDigest)
* TypeScript EIP-712 digest equals Solidity digest
* Go SignGate evaluates OPA policy (ALLOW/BLOCK)
* Go SignGate creates session authorization
* Redis reservation works atomically
* Postgres stores sessions, decisions, reservations, receipts, and UserOp lifecycle
* mandatory watcher reconciliation prevents off-chain drift
* CI passes all jobs
* README explains threat model clearly
* demo shows one allowed payment and three blocked attacks

---

# 32. Final Engineering Positioning

Railguard proves the builder understands:

* crypto payment infrastructure
* AI-agent payment risk
* account abstraction
* ERC-4337 nonce lanes
* ERC-7579 hook integration via a known adapter
* on-chain invariant enforcement
* off-chain policy engines
* deterministic audit receipts
* backend reconciliation
* adversarial testing
* safety-first infra design

The project should communicate one thing clearly:

Railguard does not merely observe payment risk. It prevents unsafe execution before funds move.
