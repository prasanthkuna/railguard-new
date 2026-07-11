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

## Production key custody (v0.1 → prod)

| Component | v0.1 (demo) | Production target |
|-----------|-------------|-------------------|
| Railguard session cosigner | `RAILGUARD_SIGNER_PRIVATE_KEY` env | HSM or MPC quorum; key never on app disk |
| Receipt signer | `RECEIPT_SIGNER_PRIVATE_KEY` env | Dedicated audit signing service with rotation |
| SignGate API key | Single shared `SIGNGATE_API_KEY` | Per-tenant scoped keys + mTLS |
| CDP credentials | Encore secrets | Same; least-privilege wallet per org |

v0.1 intentionally uses local/dev keys to prove the **protocol boundary** (hook + immutable intent + atomic budget). Production hardening is key custody and ops — not new payment features.

Configure watcher confirmation depth via `WATCHER_CONFIRMATION_DEPTH` (default `1`). CDP uses `CDP_CONFIRMATION_DEPTH` in railguard-cdp.

## Out of scope (v1)

- Paymaster bypass (no Paymaster in v1)
- Generic ERC-7579 accounts
- Arbitrary DeFi routers
- Mainnet funds
- Deep reorg rewind (confirmation depth only)
