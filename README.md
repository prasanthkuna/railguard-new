# Railguard

[![ci](https://github.com/prasanthkuna/railguard-new/actions/workflows/ci.yml/badge.svg)](https://github.com/prasanthkuna/railguard-new/actions/workflows/ci.yml)

Policy-enforced execution safety layer for AI-agent stablecoin payments.

> **Reviewer quick path (≈10 min):** `make test` → skim [docs/SECURITY_REVIEW.md](./docs/SECURITY_REVIEW.md) → run `scripts/e2e-happy-path.ps1` for canonical on-chain proof.

Railguard combines:

- **RailguardAccountAdapter** — v1 smart account with account-local session storage
- **RailguardExecutionHook** — on-chain physical enforcement (token, recipient, caps, batch leaves)
- **RailguardSessionValidator** — ERC-4337 session-key validation helper
- **Go SignGate** — OPA/Rego policy, EIP-712 signing, Redis reservations, Postgres audit trail
- **TypeScript SDK** — intent builder, sessionId derivation, EIP-712 typed data

## V1 scope

- Base Sepolia + Anvil
- USDC `transfer(address,uint256)` only
- `CALLTYPE_SINGLE` and `CALLTYPE_BATCH`
- Dual-signature session registration (owner + Railguard)
- `ALLOW` / `BLOCK` only (no Paymaster, no approval workflow in v1)

## Quick start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Go 1.22+
- Node.js 20+
- [OPA](https://www.openpolicyagent.org/docs/latest/#running-opa) (optional; or use Docker — see below)
- Docker (optional, for full stack)

### Contracts

```powershell
cd contracts
forge install foundry-rs/forge-std --no-commit
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge test -vvv
```

### Policy (OPA)

Local CLI:

```powershell
# Windows (winget)
winget install --id OpenPolicyAgent.OPA

opa test policy/
```

Without a local install, use Docker:

```powershell
powershell -File .\scripts\run-opa-tests.ps1
```

### SignGate

```powershell
cd signgate
go test ./...
go run ./cmd/api
```

### SDK

```powershell
cd sdk
npm install
npm test
```

### Full stack (Docker)

```powershell
docker compose up --build
```

SignGate listens on `http://localhost:8080`.

**Note:** `docker compose up` alone starts infra + SignGate with empty `ADAPTER_ADDRESS` / `HOOK_ADDRESS` until you deploy. That is fine for API smoke (`scripts/e2e-smoke.ps1`), but **not** the canonical chain-ready E2E. For deploy → cosign → on-chain execute → watcher ingestion, run:

```powershell
powershell -File .\scripts\e2e-happy-path.ps1
```

### Run tests

| Script | What it proves |
|--------|----------------|
| `scripts/e2e-smoke.ps1` | SignGate health + OPA evaluate (no chain) |
| `scripts/e2e-happy-path.ps1` | **Canonical PRD E2E**: deploy Anvil → SignGate cosign → on-chain register/execute → watcher `ExecutionAllowed` ingestion → signed receipt |
| `scripts/demo-onchain.ps1` | Foundry-only PRD attack demo (1 allow + 3 blocks) |

```powershell
# API smoke (docker compose up first)
powershell -File .\scripts\e2e-smoke.ps1

# Full canonical E2E (deploy + watcher proof)
powershell -File .\scripts\e2e-happy-path.ps1

# On-chain attack demo only
powershell -File .\scripts\demo-onchain.ps1
```

See [docs/SECURITY_REVIEW.md](./docs/SECURITY_REVIEW.md) for the reviewer checklist.

## Architecture

```text
AI Agent → SDK → SignGate (OPA, Redis, Postgres, Watcher)
                      ↓
         RailguardAccountAdapter + Hook
                      ↓
              ERC-4337 / Base Sepolia
```

**Asset safety** is enforced on-chain by the execution hook. SignGate provides policy, reservation, and audit support.

## API

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check (public) |
| POST | `/v1/intents/evaluate` | OPA policy evaluation (public) |
| POST | `/v1/sessions/register` | Prepare session + Railguard signature (`X-SignGate-API-Key`) |
| POST | `/v1/reservations/reserve` | Redis budget reservation (`X-SignGate-API-Key`) |
| POST | `/v1/userops/submitted` | Mark UserOp submitted (`X-SignGate-API-Key`) |
| POST | `/v1/userops/finalized` | Mark UserOp finalized (`X-SignGate-API-Key`) |
| GET | `/v1/receipts/{decisionId}` | Fetch audit receipt (`X-SignGate-API-Key`) |
| GET | `/v1/reconciliation/executions/{sessionId}` | Watcher-ingested chain execution (`X-SignGate-API-Key`) |

## Threat tests

Foundry tests cover:

- Dual-signature registration
- Single/batch spend caps
- Wrong recipient/target
- Delegatecall / unknown mode rejection
- Execution digest replay
- Session expiry
- `allowBatch` enforcement

## Docs

| Doc | Purpose |
|-----|---------|
| [docs/HIRING_PITCH.md](./docs/HIRING_PITCH.md) | One-page hiring narrative |
| [docs/SECURITY_REVIEW.md](./docs/SECURITY_REVIEW.md) | Reviewer checklist |
| [docs/TEST_MATRIX.md](./docs/TEST_MATRIX.md) | Threat / test coverage map |
| [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) | System design |
| [prd.md](./prd.md) | Product requirements |
| [trd.md](./trd.md) | Technical requirements |

## License

[MIT](./LICENSE)
