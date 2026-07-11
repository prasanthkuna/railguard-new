# Hardening Agent Payments: 4 Bugs I Fixed in Railguard

*Draft for LinkedIn, dev.to, or personal blog. No new scope — documents v0.1 remediation.*

---

AI agents will pay for APIs and vendors via x402 and stablecoin rails. The scary part is not “can we sign a payment?” — it is **what happens when off-chain policy, budgets, and chain truth disagree**.

I built Railguard as a v0.1 reference stack and ran a three-repo security audit. The failures clustered in **atomicity** and **truth convergence**, not naive input validation. Here are four bug classes I fixed.

---

## 1. Mutable ALLOW decisions

**The bug:** An intent hash excluded session limits (`maxPerTransfer`, `maxTotalSpend`). A client could obtain ALLOW on small caps, mutate the stored intent, and register a session with larger physical limits than the consumed decision approved.

**The fix:** Include all physical limit fields in the canonical intent hash. Persist intents with `ON CONFLICT DO NOTHING` so approved facts cannot change behind an existing decision.

**Line to remember:**

> Authorization is only meaningful if the approved facts cannot change after approval.

**Proof:** `signgate/internal/intent/intent_test.go` — `TestHashIncludesLimits`

---

## 2. Budget TOCTOU (read-then-write)

**The bug:** x402 rolling-window enforcement used `sumSpendInWindow → pay → recordSpend`. Concurrent payments could all observe the same headroom and settle above the cap.

**The fix:** One primitive: `authorizePayment` → atomic `claimReplay` + `reserveBudget` → `commitAuthorization` / `releaseAuthorization`. Budget enforcement is a **reservation**, not a read.

**Line to remember:**

> Budget enforcement is not a read — it is a reservation.

**Proof:** `x402-guard/packages/policy/src/authorize.test.ts`, `fault-injection.test.ts`

---

## 3. Post-broadcast lies

**The bug:** CDP returned a transaction hash, then a DB or audit step failed. Status became `failed`. A retry could double-pay because the system lied about whether money had left the provider.

**The fix:** Track `broadcastedTxHash` explicitly. After broadcast, errors become `submitted` / `unknown`, never `failed`. A reconciler cron converges truth from chain receipts.

**Line to remember:**

> Once money leaves the provider, exception text is not financial truth.

**Proof:** `coinbase/apps/api/payment-state.test.ts`, `execution-claim.test.ts`

---

## 4. FIFO reconciliation (wrong identity)

**The bug:** The chain watcher committed the oldest pending reservation per session — not the execution that actually occurred. Direct or out-of-order executions could misattribute spend.

**The fix:** `ExecutionAllowed` emits `executionDigest`. The watcher and Postgres reconcile **by digest**, not queue position.

**Line to remember:**

> Financial reconciliation must match by identity, not queue position.

**Proof:** `scripts/e2e-happy-path.ps1` — watcher ingests exact execution

---

## What I did not add

Paymaster, Solana, multi-chain, dashboards, or “production-ready” marketing. v0.1 is a **reference implementation** with E2E proof and documented gaps (reorg rewind, HSM keys, full Postgres fault-injection).

---

## Try it

One link: [PORTFOLIO.md](https://github.com/prasanthkuna/railguard-new/blob/master/docs/PORTFOLIO.md)

```powershell
cd x402-guard && bun test packages/policy/src/authorize.test.ts
```

---

*Railguard: policy-enforced agent stablecoin payments. Three boundaries — pre-sign x402, on-chain hook, CDP reconciliation — one invariant: terminal payment state must converge to chain evidence.*
