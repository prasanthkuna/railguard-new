# Pitch — Coinbase / Base

**Audience:** Base ecosystem, CDP, x402, agent payments

## One paragraph

x402 agent payments need policy, replay protection, rolling budgets, and settlement reconciliation before and after signing. Railguard v0.1 adds a pre-sign layer (`x402-guard` with atomic `authorizePayment`), a Base Sepolia / Anvil smart-account hook proof (`railguard-new`), and a CDP invoice execution demo with post-broadcast truth handling (`railguard-cdp`). I hardened the glue: immutable ALLOW facts, budget reservations, and chain-backed reconciliation.

## Why Base

- USDC on Base Sepolia in v0.1 scope
- CDP SDK integration with explicit `PAYMENT_MODE` and confirmation depth
- x402 aligns with agent HTTP payments — guardrails are the missing production layer

## Proof (5 min)

```powershell
cd x402-guard && bun test packages/policy/src/authorize.test.ts
```

## Link

[PORTFOLIO.md](./PORTFOLIO.md)
