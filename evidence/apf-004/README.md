# APF-004 — Transfer fact mismatch

## Principle

> Transaction success is transport evidence. Matching transfer facts are payment evidence.

**INV-002:** Confirmation requires matching chain, token, sender, recipient, and amount.

## Live proof (Base Sepolia)

Using tx `0x80cac8ed...`:

| Scenario | Expected recipient | Result |
|----------|-------------------|--------|
| Correct facts | `0xc0d30deb...bf8c5` | CONFIRMED |
| Wrong recipient | `0x000...dead` | RECONCILIATION_REQUIRED |

## Reproduce

```bash
cd coinbase
TESTNET_INTEGRATION=1 \
BASE_SEPOLIA_TX_HASH=0x80cac8ed62ca6ef0797f1a6244ab52e13e6c39ea23f3a0fa58e2fa95623872dd \
  bun test packages/settlement/src/base-sepolia.integration.test.ts
```

## Implementation

- `packages/settlement/src/index.ts` — `verifyTransferFacts`
- `apps/api/paymentReconciliation.ts` — guard stays frozen on mismatch
