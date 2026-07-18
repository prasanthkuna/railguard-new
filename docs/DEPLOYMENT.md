# Deployment & operations

Last updated: 2026-07-18

## Live URLs

| Surface | URL |
|---------|-----|
| API (staging) | https://staging-railguard-s4ii.encr.app |
| Web (Vercel) | https://coinbase-eight-xi.vercel.app |

## Deploy API (Encore)

Migration `008_payment_lifecycle_correlation` applies automatically on Encore deploy.

```powershell
cd coinbase
git push encore main
```

Verify after deploy:

```powershell
$env:RAILGUARD_BASE_URL = "https://staging-railguard-s4ii.encr.app"
bun run verify:demo
```

## Deploy web (Vercel)

Vercel auto-deploys from `prasanthkuna/railguard-cdp` on push to `main`.

## Testnet evidence (grant-ready artifacts)

```powershell
powershell -NoProfile -File railguard-new/scripts/testnet-evidence.ps1
```

| Network | Command | Artifact |
|---------|---------|----------|
| Stellar testnet | `cd stellar-payment-assurance-kit && npm run testnet-evidence` | `evidence/testnet-live.json` |
| Base Sepolia | `cd coinbase && bun run testnet-evidence` | `evidence/base-sepolia-live.json` |
| On-chain APF-006 | `forge test --match-contract PrdDemo` | CI logs |

## Full product verification

```powershell
powershell -NoProfile -File railguard-new/scripts/failure-lab.ps1
```

## Repos (public)

| Repo | GitHub |
|------|--------|
| railguard-new | prasanthkuna/railguard-new |
| railguard-cdp | prasanthkuna/railguard-cdp |
| x402-guard | prasanthkuna/x402-guard |
| agent-payment-failure-lab | prasanthkuna/agent-payment-failure-lab |
| gnu-taler-merchant-reliability-lab | prasanthkuna/gnu-taler-merchant-reliability-lab |
| stellar-payment-assurance-kit | prasanthkuna/stellar-payment-assurance-kit |

`grant-ops` is **private** — never publish.
