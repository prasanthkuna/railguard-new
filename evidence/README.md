# Public evidence index

Sanitized, reviewer-verifiable proof artifacts. No secrets, credentials, or tenant data.

| Record | Network | What it proves | Reproduce |
|--------|---------|----------------|-----------|
| [cdp-base-sepolia](./cdp-base-sepolia/) | Base Sepolia | Live USDC transfer + settlement-fact verification (INV-002) | `cd coinbase && bun run scripts/testnet-evidence.ts` |
| [stellar-testnet](./stellar-testnet/) | Stellar testnet | Horizon-verified payment + memo binding | `cd stellar-payment-assurance-kit && npm run testnet-evidence` |
| [apf-003](./apf-003/) | In-memory + CDP tests | Post-broadcast crash keeps guard frozen (INV-001) | `cd agent-payment-failure-lab && npm run lab -- --profiles APF-003` |
| [apf-004](./apf-004/) | Base Sepolia RPC | Wrong transfer facts → RECONCILIATION_REQUIRED | `cd coinbase && TESTNET_INTEGRATION=1 bun test packages/settlement` |
| [gate-d-live-flow](./gate-d-live-flow/) | Base Sepolia | End-to-end CDP lifecycle + crash recovery demonstration | See README |

## Verification principle

> Transaction success is transport evidence. Matching transfer facts are payment evidence.

## Regenerate all

```powershell
powershell -NoProfile -File scripts/testnet-evidence.ps1
```

Or per-network:

```bash
# Base Sepolia
cd coinbase
BASE_SEPOLIA_TX_HASH=0x80cac8ed62ca6ef0797f1a6244ab52e13e6c39ea23f3a0fa58e2fa95623872dd \
  bun run scripts/testnet-evidence.ts

# Stellar testnet
cd stellar-payment-assurance-kit
npm run testnet-evidence

# Failure profiles
cd agent-payment-failure-lab
npm run lab -- --profiles APF-003,APF-004 --output evidence/apf-results.json
```

## Schema

Each `manifest.json` includes:

- `repository_commit` — git SHA when generated
- `profile_version` — APF/SPA profile ID and version
- `network` — chain or test environment
- `transaction_hash` + `explorer_reference`
- `expected` / `observed` transfer facts
- `state_transitions` — payment and guard lifecycle
- `evidence_hash` — SHA-256 of canonical manifest body

Last updated: 2026-07-18
