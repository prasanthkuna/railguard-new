# Railguard Architecture

## Layers

0. **[x402-guard](https://github.com/prasanthkuna/x402-guard)** — pre-sign agent payment policy (caps, domains, replay, receipts); optional, off-chain
1. **TypeScript SDK** — intent building, sessionId derivation, EIP-712 typed data, `createX402Guard()`
2. **Go SignGate** — OPA policy, reservations, audit receipts, watcher reconciliation
3. **RailguardAccountAdapter** — account-local session storage, dual-signature registration
4. **RailguardExecutionHook** — physical on-chain enforcement boundary
5. **RailguardSessionValidator** — session-key UserOp validation helper

## Stack (agent payments)

```text
Agent HTTP call (x402)
  → x402-guard.evaluate()     [off-chain policy — fail closed]
  → x402 signature
  → SDK intent + SignGate     [session policy — advisory]
  → RailguardExecutionHook    [on-chain hard ceiling]
```

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
