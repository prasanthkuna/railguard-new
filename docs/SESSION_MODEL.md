# Session Model

## Nonce lane

```text
UserOp.nonce = (uint192 nonceKey) << 64 | (uint64 sequence)
one active session per account + nonceKey
```

## Registration

Both account owner and Railguard sign the same `SessionAuthorization` EIP-712 struct.

Session key may spend inside the box but cannot register or widen sessions.

## Storage

```solidity
mapping(address account => mapping(uint192 nonceKey => SessionConfig)) sessions;
```

Lives in `RailguardAccountAdapter` only (no global registry in v1).

## Physical fields

`sessionKey`, `token`, `allowedTarget`, `allowedRecipient`, `allowedSelector`, `maxPerTransfer`, `maxTotalSpend`, `validAfter`, `validUntil`, `allowBatch`

## Metadata

`policyHash` — audit binding only, excluded from `sessionId`
