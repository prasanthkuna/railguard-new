# Railguard v0.1-reference

**Tag:** `v0.1-reference` (all three repos)

## What this release demonstrates

- Pre-sign x402 policy enforcement (`x402-guard`)
- Atomic replay and budget authorization (`authorizePayment`)
- Session-scoped on-chain execution proof (SignGate + Solidity hook)
- CDP invoice payment state machine (broadcast truth, reconciler)
- Audit + reconciliation (`executionDigest`, hash-chained audit)
- Failure-mode remediation tests + Docker E2E proof
- Portfolio docs with honest production gaps

## Not in scope (v0.1)

Paymaster, Solana, multi-chain, dashboard, MPC/HSM implementation, deep reorg engine, arbitrary router parsing, mainnet funds.

## Proof commands

```powershell
# x402-guard
cd x402-guard && bun test

# railguard-new
cd railguard-new/signgate && go test ./...
cd ../contracts && forge test
powershell -File .\scripts\e2e-happy-path.ps1

# railguard-cdp
cd coinbase && bun test apps/api packages && bun run lint
```

## Sibling tags

| Repo | Tag |
|------|-----|
| [railguard-new](https://github.com/prasanthkuna/railguard-new/releases/tag/v0.1-reference) | `v0.1-reference` |
| [x402-guard](https://github.com/prasanthkuna/x402-guard/releases/tag/v0.1-reference) | `v0.1-reference` |
| [railguard-cdp](https://github.com/prasanthkuna/railguard-cdp/releases/tag/v0.1-reference) | `v0.1-reference` |

**Start here:** [PORTFOLIO.md](./PORTFOLIO.md)
