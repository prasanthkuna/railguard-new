# Base Sepolia USDC — live settlement evidence

## Summary

Read-only verification of a real Base Sepolia USDC transfer against expected settlement facts.

| Field | Value |
|-------|-------|
| Network | Base Sepolia (chain ID 84532) |
| Tx hash | `0x80cac8ed62ca6ef0797f1a6244ab52e13e6c39ea23f3a0fa58e2fa95623872dd` |
| Explorer | [sepolia.basescan.org](https://sepolia.basescan.org/tx/0x80cac8ed62ca6ef0797f1a6244ab52e13e6c39ea23f3a0fa58e2fa95623872dd) |
| Settlement | CONFIRMED |
| Amount | 0.5 USDC (500000 base units) |

## Invariant

**INV-002:** Confirmation requires matching chain, token, sender, recipient, and amount.

## Reproduce

```bash
cd railguard-cdp  # or coinbase
BASE_SEPOLIA_TX_HASH=0x80cac8ed62ca6ef0797f1a6244ab52e13e6c39ea23f3a0fa58e2fa95623872dd \
  bun run scripts/testnet-evidence.ts
```

Expected output: `"settlement": { "status": "CONFIRMED" }`

## Implementation

- `packages/settlement/src/base-sepolia.ts` — live RPC verification
- `packages/settlement/src/index.ts` — `verifyTransferFacts`
