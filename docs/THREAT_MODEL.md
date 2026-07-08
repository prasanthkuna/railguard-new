# Threat Model (v1)

## In scope

| Threat | Mitigation |
|--------|------------|
| Wrong recipient | Hook leaf validation |
| Wrong token/target | `allowedTarget == token`, target check |
| Over per-transfer cap | `maxPerTransfer` |
| Cumulative spend drift | `sessionSpend` + frame accumulator |
| Batch leaf injection | Inspect every leaf |
| Delegatecall / unknown mode | Reject non single/batch |
| Approve / transferFrom | Selector denylist |
| Session replay | ERC-4337 nonce + `executionDigest` |
| Unauthorized registration | Owner + Railguard dual EIP-712 sig |
| Expired / not-yet-valid session | `validAfter` / `validUntil` |

## Out of scope (v1)

- Paymaster bypass (no Paymaster in v1)
- Generic ERC-7579 accounts
- Arbitrary DeFi routers
- HSM / MPC / TEE
- Mainnet funds
