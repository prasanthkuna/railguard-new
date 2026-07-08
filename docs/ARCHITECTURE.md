# Railguard Architecture

## Layers

1. **TypeScript SDK** — intent building, sessionId derivation, EIP-712 typed data
2. **Go SignGate** — OPA policy, reservations, audit receipts, watcher reconciliation
3. **RailguardAccountAdapter** — account-local session storage, dual-signature registration
4. **RailguardExecutionHook** — physical on-chain enforcement boundary
5. **RailguardSessionValidator** — session-key UserOp validation helper

## Safety model

- On-chain session caps are **asset truth**
- Off-chain policy/reservations are **advisory**
- Direct UserOp submission with valid sessionKey is allowed; hook still enforces

## Session identity

```text
sessionId = keccak256(chainId, adapter, account, nonceKey, sessionConfigPhysicalHash)
```

`policyHash` is audit metadata only.

## Execution flow

```text
executeWithSession(nonceKey, mode, executionCalldata)
  → hook.preCheck
  → ERC-7579 single/batch execution
  → hook.postCheck (commits spend + executionDigest)
```
