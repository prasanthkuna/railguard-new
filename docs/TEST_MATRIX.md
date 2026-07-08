# Test Matrix

## Contracts (Foundry)

- Session registration (dual sig, duplicate nonce, target==token, zero addresses)
- Single transfer allow/reject
- Batch allow/reject/allowBatch flag
- Cumulative spend cap
- Delegatecall / unknown mode
- Approve selector reject
- Execution digest replay
- Expired / not-yet-valid session
- Mutation (wrong target, over amount, self-call)
- Session validator key checks
- **ThreatMatrixGaps.t.sol** — TRD §21 registration/execution gaps
- **PrdDemo.t.sol** — PRD demo (1 allow + 3 blocks)
- **PhysicalVector.t.sol** — mirrors `fixtures/physical_vectors.json`

```powershell
powershell -File scripts/demo-onchain.ps1
```

## SignGate (Go)

- Intent hashing (Keccak, cross-language)
- OPA allow/block + physical vector differential
- SessionId / EIP-712 vectors
- Reservation idempotency + budget locks
- Receipt hash + ECDSA sign/recover
- API key auth, production config validation
- Watcher reconciliation (stale UserOp, re-scan window)

## SDK (Vitest) — 12 tests

- sessionId derivation
- intent builder
- EIP-712 typed data shape
- receipt hash + `verifyReceiptSignature`

## CI jobs

`contracts` | `go-tests` | `opa-tests` | `typescript-tests` | `differential-tests`

## E2E

| Script | Proves |
|--------|--------|
| `e2e-smoke.ps1` | SignGate health + OPA evaluate |
| `e2e-happy-path.ps1` | Deploy → cosign → on-chain execute → watcher ingestion → receipt |
| `demo-onchain.ps1` | Foundry allow + 3 block attacks |

```powershell
powershell -File scripts/e2e-happy-path.ps1
```
