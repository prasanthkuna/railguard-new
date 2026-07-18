# Gate D — Undeniable live CDP flow

## Happy path

```text
Invoice uploaded
  → facts extracted
  → deterministic policy
  → approval snapshot
  → durable payment intent
  → x402 budget reservation
  → real CDP wallet execution
  → Base Sepolia USDC transfer
  → settlement-fact verification
  → guard commit
  → audit evidence
```

## Crash recovery path (APF-003)

```text
Broadcast succeeds
  → application failure injected
  → payment enters UNKNOWN
  → reservation stays FROZEN
  → retry blocked
  → reconciler verifies transfer facts
  → authorization COMMITTED
```

## Live transaction proof

| Field | Value |
|-------|-------|
| Network | Base Sepolia (84532) |
| Tx | `0x80cac8ed62ca6ef0797f1a6244ab52e13e6c39ea23f3a0fa58e2fa95623872dd` |
| Explorer | [basescan](https://sepolia.basescan.org/tx/0x80cac8ed62ca6ef0797f1a6244ab52e13e6c39ea23f3a0fa58e2fa95623872dd) |
| Token | USDC `0x036CbD53842c5426634e7929541eC2318f3dCF7e` |
| Amount | 0.5 USDC |
| Settlement | CONFIRMED (transfer facts match) |

## Three commands to verify everything

```bash
# 1. Live chain evidence
cd coinbase
BASE_SEPOLIA_TX_HASH=0x80cac8ed62ca6ef0797f1a6244ab52e13e6c39ea23f3a0fa58e2fa95623872dd \
  bun run scripts/testnet-evidence.ts

# 2. Lifecycle invariants (17 tests)
bun test apps/api/payment-lifecycle.test.ts apps/api/payment-state.test.ts

# 3. Adversarial profiles
cd ../agent-payment-failure-lab
npm run lab -- --profiles APF-003,APF-004
```

## What this supports

- CDP Founders Fuel application
- Coinbase hiring technical demonstration
- Grant evidence packages
- External maintainer review

## Known limitation

This evidence demonstrates settlement verification and lifecycle correctness on Base Sepolia testnet. Full CDP invoice→wallet orchestration in `PAYMENT_MODE=live` requires CDP credentials and is not reproduced in this public manifest.
