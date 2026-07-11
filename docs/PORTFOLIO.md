# Railguard Portfolio — Start Here

**One-line pitch:** Policy-enforced payment safety for AI-agent stablecoin payments — from pre-sign x402 policy through session-scoped on-chain enforcement to CDP invoice execution and audit reconciliation.

**Status:** Completed **v0.1 reference implementation** with E2E proof, CI green, and documented production gaps. Not marketed as production-ready for mainnet funds.

---

## Core invariant (lead with this in interviews)

```text
Intent → Policy → Session → Signature → Hook → Receipt → Reconcile
```

> We separated policy intelligence from asset safety and hardened the glue: every ALLOW binds to immutable facts, every budget reserves atomically, and every terminal payment state converges to chain evidence.

---

## Three enforcement boundaries (not three random repos)

| # | Boundary | Repo | What it proves |
|---|----------|------|----------------|
| 1 | **Pre-sign x402 policy** | [x402-guard](https://github.com/prasanthkuna/x402-guard) | Fail-closed caps, domains, replay, rolling budgets **before** payment |
| 2 | **Session + on-chain ceiling** | [railguard-new](https://github.com/prasanthkuna/railguard-new) (this repo) | SignGate, OPA, hook, watcher — physical enforcement on-chain |
| 3 | **Invoice / CDP product** | [railguard-cdp](https://github.com/prasanthkuna/railguard-cdp) | Human approvals, CDP broadcast, exactly-once state, reconciler |

**CDP path vs hook path:** The CDP demo proves B2B invoice workflow, broadcast truth, and reconciliation. The Railguard hook proves smart-account-native physical enforcement (token, recipient, caps). In v0.1 they share policy and audit **concepts** (`authorizePayment`, receipts, snapshot hashes); full routing from every CDP transfer through a Railguard smart account is future hardening — not hidden.

---

## Source of truth

| Question | Source of truth |
|----------|-----------------|
| Can this HTTP/x402 payment be attempted? | `x402-guard` authorization store (`claimReplay` + `reserveBudget`) |
| Can this Railguard session move funds on-chain? | On-chain hook + session config (caps, token, recipient) |
| Did CDP broadcast money? | `broadcastedTxHash` + CDP provider response |
| Did the transfer actually succeed? | Chain receipt `status === "success"` |
| What happened for audit? | Hash-chained audit events + signed receipts |
| What should UI show for ambiguous state? | `submitted` / `unknown` until reconciler resolves |
| Which reservation matches which execution? | `executionDigest` (not queue position) |

---

## 5-minute demo

```powershell
# 1) Atomic x402 budget (3 min)
cd x402-guard
bun test packages/policy/src/authorize.test.ts

# 2) On-chain attacks blocked (5 min)
cd ..\railguard-new\contracts
forge test --match-contract PrdDemo -vv

# 3) Full loop (10–15 min)
cd ..
docker compose up -d --build
powershell -File .\scripts\apply-db-migrations.ps1
powershell -File .\scripts\e2e-happy-path.ps1
```

---

## Architecture diagram

[THREE_PROJECT_SYSTEM_DIAGRAM.md](./THREE_PROJECT_SYSTEM_DIAGRAM.md) — single master Mermaid diagram.

---

## Audit → fix → proof story

[FAILURE_MODES_FIXED.md](./FAILURE_MODES_FIXED.md) — bug class, exploit, fix, test command per row.

[THREE_PROJECT_IMPROVEMENTS_AND_INTERVIEW_PREP.md](./THREE_PROJECT_IMPROVEMENTS_AND_INTERVIEW_PREP.md) — pass 3–5 remediation, STAR stories, Q&A.

---

## Known limitations (v0.1)

- No Paymaster, no arbitrary DeFi router parsing, no multi-chain in scope
- SignGate signer keys are dev/local — production needs HSM/MPC ([THREAT_MODEL.md](./THREAT_MODEL.md))
- Watcher: confirmation depth configurable; deep reorg rewind not complete
- Fault-injection at full Postgres API boundaries: partial (unit tests on primitives)
- Mainnet funds: out of scope

---

## Repos & CI

| Repo | CI | Canonical proof |
|------|-----|-----------------|
| [railguard-new](https://github.com/prasanthkuna/railguard-new) | [![ci](https://github.com/prasanthkuna/railguard-new/actions/workflows/ci.yml/badge.svg)](https://github.com/prasanthkuna/railguard-new/actions/workflows/ci.yml) | `e2e-happy-path.ps1` |
| [x402-guard](https://github.com/prasanthkuna/x402-guard) | [![CI](https://github.com/prasanthkuna/x402-guard/actions/workflows/ci.yml/badge.svg)](https://github.com/prasanthkuna/x402-guard/actions/workflows/ci.yml) | `bun test` |
| [railguard-cdp](https://github.com/prasanthkuna/railguard-cdp) | PR checks | `bun test apps/api` |
