# Pitch — Backend / platform engineering

**Audience:** Payments infra, distributed systems, Go/TypeScript platform teams

## One paragraph

Railguard is a money-moving state machine across three repos: idempotent execution claims, atomic budget reservation in Postgres and in-memory stores, Redis advisory aggregates with session-scoped TTL, block-by-block watcher ingest with confirmation depth, transactional audit append, and CI/E2E proof from clean clone. The audit found TOCTOU and truth-convergence bugs — not missing validators — and I shipped fixes with tests at each boundary.

## Systems topics to discuss

- **Idempotency:** execution idempotency keys, `ON CONFLICT DO NOTHING` on intents
- **Atomicity:** `authorizePayment`, advisory locks + single-tx audit
- **Reconciliation:** cron for `submitted`/`unknown`, `executionDigest` matching
- **CI:** Linux lockfile sync, sibling x402-guard checkout, Docker E2E

## Proof

```powershell
cd railguard-new\signgate && go test ./...
cd ..\coinbase && bun test apps/api/payment-state.test.ts apps/api/execution-claim.test.ts
```

## Link

[PORTFOLIO.md](./PORTFOLIO.md) · [FAILURE_MODES_FIXED.md](./FAILURE_MODES_FIXED.md)
