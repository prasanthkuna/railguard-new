# My read of `v3plan.md` and execution plan

I read `railguard-new/docs/v3plan.md` end-to-end and checked the three repos against it. The plan is coherent: **fix payment lifecycle correctness first**, then use that as the foundation for grants, hiring, and the Agent Payment Failure Lab.

Below is what exists today, what’s missing, and how I’d execute it.

---

## Strategic thesis (what v3 is really about)

You’re not building three random grant apps. You’re building one expertise:

> **Prove whether programmable payments were authorized correctly, executed safely, and reconciled accurately.**

The reusable lifecycle:

```text
Intent → Policy → Authorization → Reservation → Execution
→ Settlement verification → Reconciliation → Audit evidence
```

| Repo | Role in lifecycle |
|------|-------------------|
| **x402-guard** | Pre-payment policy + atomic budget authorization |
| **railguard-new** | Delegated smart-account hard enforcement |
| **railguard-cdp** (`coinbase/`) | Enterprise invoice → approval → CDP → reconcile |

**v3 adds a fourth artifact:** `agent-payment-failure-lab` — executable proof that the lifecycle holds under adversarial conditions.

---

## Priority 1: Foundation fixes (block everything else)

v3plan is right: **no major grant should ship while the CDP lifecycle has a known accounting bug.** I confirmed it in code.

### Bug 1 — Post-broadcast releases guard reservation (CRITICAL)

In `coinbase/apps/api/api.ts`, when broadcast succeeds but post-broadcast steps fail:

```986:988:coinbase/apps/api/api.ts
        if (guardAuthorizationId) {
          await releasePaymentGuardAuthorization(actor.organizationID, guardAuthorizationId)
        }
```

Payment becomes `unknown`, but the guard authorization is **released**. Budget is overstated; another payment can be authorized.

**v3 rule violated:** *“A transaction hash means the authorization must remain reserved.”*

### Bug 2 — Reconciler doesn’t commit guard on recovery

`reconcile.ts` moves `unknown` → `confirmed` but never calls `commitPaymentGuardSpend()`. A crash-recovered payment can confirm without committing budget.

### Bug 3 — Settlement verification is receipt-only

`waitForTransferConfirmation()` only checks `receipt.status === "success"`. It does **not** verify:

- correct token contract  
- correct sender / recipient / amount  
- `Transfer` event semantics  

Wrong-recipient success would incorrectly become `CONFIRMED`.

### Bug 4 — Missing durable correlation

`payment_intents` has `tx_hash` but not the guard correlation fields v3 requires (`guard_fingerprint`, `guard_authorization_id`, `guard_status`, `settlement_status`, `expected_*`, etc.). Restart loses the link between intent ↔ authorization ↔ tx.

### Bug 5 — README positioning

`x402-guard/README.md` still claims x402 has no replay/idempotency. v3 wants:

> *“x402 provides protocol hooks and payment identifiers. This project provides durable multi-agent budget state, atomic reservations, crash recovery and settlement reconciliation.”*

### Bug 6 — Cross-platform reviewer path

`railguard-new/Makefile` exists but `e2e` / `demo` are PowerShell-only. v3 requires portable:

```bash
make setup && make test && make e2e && make failure-lab
```

on Linux, macOS, and Windows.

---

## My execution plan (phased)

### Phase 0 — Lock scope (1–2 days)

**Goal:** Turn v3plan into trackable work packages.

| Work package | Repo | Owner |
|--------------|------|-------|
| WP-1 Lifecycle state machine | `coinbase/` | P1 |
| WP-2 Settlement fact verifier | `coinbase/packages/cdp` or new `packages/settlement` | P1 |
| WP-3 Guard correlation schema | `coinbase/` migration 008 | P1 |
| WP-4 Adversarial test suite | `coinbase/` + later failure-lab | P1 |
| WP-5 README + package rename | `x402-guard/` | P1 |
| WP-6 Portable make targets | all 3 repos | P1 |
| WP-7 Failure lab scaffold | new repo | P3 |
| WP-8 NLnet Taler proposal | new repo | P2 |
| WP-9 Stellar SCF proposal | new repo | P2 |

Create private `grant-ops/` as v3 describes (opportunities, evidence, budgets).

---

### Phase 1 — Fix the payment lifecycle (2–3 weeks) — **DO THIS FIRST**

#### 1A. Implement the v3 state machine in CDP

Replace current behavior with:

```text
AUTHORIZED → RESERVED → EXECUTING → SUBMITTED
  ├── CONFIRMED → COMMITTED
  ├── REVERTED → RELEASED
  ├── UNKNOWN → FROZEN (reservation held)
  └── RECONCILIATION_REQUIRED → FROZEN
```

**Concrete changes:**

| File | Change |
|------|--------|
| `api.ts` `executePaymentIntent` | On post-broadcast failure with `tx_hash`: set `unknown`, **do not** `releaseAuthorization` |
| `api.ts` | Only `releaseAuthorization` when broadcast definitely did not occur |
| `reconcile.ts` | On confirm: run settlement verifier → `commitPaymentGuardSpend` → `COMMITTED` |
| `reconcile.ts` | On wrong transfer facts: `RECONCILIATION_REQUIRED`, keep frozen |
| `paymentState.ts` | Add `reverted`, `reconciliation_required`, guard status helpers |
| Migration `008` | Add all correlation + settlement fields to `payment_intents` |

Persist at execute time:

```text
guard_fingerprint, guard_authorization_id, guard_receipt_id,
guard_status, expected_chain_id, expected_token, expected_sender,
expected_recipient, expected_amount, settlement_status
```

#### 1B. Build `verifyTransferFacts()` 

New function in `providers.ts` (or `@railguard/settlement`):

```text
Input: txHash + expected {chain, token, sender, recipient, amount}
Output: CONFIRMED | REVERTED | RECONCILIATION_REQUIRED | PENDING
```

Parse logs for USDC `Transfer(address,address,uint256)`. Wrong recipient/amount → `RECONCILIATION_REQUIRED`, not `CONFIRMED`.

#### 1C. Adversarial tests (v3 required list)

Add to `coinbase/apps/api/`:

| Test | Profile |
|------|---------|
| Crash before broadcast | release auth OK |
| Crash after broadcast | auth stays `reserved`, retry blocked |
| Crash after tx hash stored | reconciler commits |
| Concurrent duplicate execute | exactly-once claim |
| Late confirmation | idempotent reconcile |
| Wrong recipient tx | `RECONCILIATION_REQUIRED` |
| Wrong amount tx | `RECONCILIATION_REQUIRED` |
| Repeated reconciler | idempotent |
| Process restart | no in-memory guard state loss |

These become **APF-003** and **APF-004** seeds for the failure lab.

#### 1D. x402-guard alignment

- Update README claims table  
- Plan rename to `@prasanthkuna/payment-policy`, `payment-state`, `x402-adapter` (after legal/brand check)  
- Ensure `authorizePayment` states map cleanly to CDP `guard_status` (`reserved` / `committed` / `released` / `frozen`)

#### 1E. Portable make targets

| Repo | Add |
|------|-----|
| `railguard-new` | `make failure-lab`, bash equivalents for e2e |
| `coinbase` | `Makefile`: setup, test, e2e, failure-lab |
| `x402-guard` | `Makefile`: setup, test |

Use `pwsh` only as fallback on Windows, not as the only path.

**Phase 1 exit criteria:** All adversarial tests green; `FAILURE_MODES_FIXED.md` updated; demo shows crash-after-broadcast with frozen budget.

---

### Phase 2 — Grant applications — **PRODUCT COMPLETE, READY TO APPLY**

**Strategy:** Build first, grant after. Full features, no compromise.

| Product | Status |
|---------|--------|
| Agent Payment Failure Lab (APF-001..006) | **Shipped** — `agent-payment-failure-lab/` |
| GNU Taler Lab (TMR-001..008) | **Shipped** |
| Stellar Kit (SPA-001..005) | **Shipped** |
| CDP Phase 1 lifecycle | **Shipped** (apply migration 008) |
| Grant applications | **Rewritten** for extension funding |

```powershell
powershell -NoProfile -File railguard-new/scripts/failure-lab.ps1
```

See `grant-ops/decisions/product-complete.md` for apply order.

#### 2A. GNU Taler Merchant Reliability Lab (NLnet)

- Separate repo, not a renamed x402 adapter  
- Reuse failure-lab runner infrastructure (disclose in application)  
- Scope: order binding, duplicate fulfilment, crash recovery, refund lifecycle  
- Ask: **€20k–€30k**  
- Deliverables: vulnerable + fixed merchant fixtures, CI, upstream contribution path

#### 2B. Stellar Payment Assurance Kit (SCF)

- Native Stellar: accounts, envelopes, Soroban events, memo binding  
- Ask: **$25k–$45k** (not max $150k first time)  
- Pitch: intent ↔ tx ↔ token movement ↔ accounting  
- Need: one Stellar dev conversation + testnet evidence before submit

#### 2C. Prepare but don’t rush

| Program | Status per v3 |
|---------|----------------|
| Circle grants | Portal conflicted — prepare Arc module, submit when open |
| Base Builder Grant | After external usage + mainnet fixture |
| CDP Founders Fuel | After public launch URL + recovery profile |
| x402 Foundation | Standards contribution, not a grant |

---

### Phase 3 — Agent Payment Failure Lab (flagship OSS)

New repo: `agent-payment-failure-lab/`

```
profiles/     APF-001..006
fixtures/     vulnerable-x402, fixed-x402, vulnerable-cdp, fixed-cdp, smart-account
adapters/     base, cdp, x402, circle-arc
reporters/    json, junit, sarif
github-action/
```

| Profile | Source fixture |
|---------|----------------|
| APF-001 Replay | `x402-guard` `authorize.test.ts` |
| APF-002 Budget race | `fault-injection.test.ts` |
| APF-003 Crash after broadcast | fixed CDP path |
| APF-004 Wrong transfer | new settlement verifier |
| APF-005 Stale approval | `policySnapshot.ts` |
| APF-006 Middleware bypass | `railguard-new` `PrdDemo` forge tests |

**Output contract:** JSON evidence with `profile`, `result`, `invariant`, `observed_state`, `severity`, `evidence_hash`.

Start with **4–6 deeply proven profiles**, not 20 shallow ones.

**How the three repos plug in:**

```text
x402-guard     → reference for atomic auth + receipts
railguard-new  → on-chain hard-enforcement fixture (APF-006)
railguard-cdp  → enterprise fixture (APF-003, APF-005)
```

---

### Phase 4 — Ecosystem modules (after failure lab has users)

Activate **one at a time** only after external validation:

| Module | Funder | When |
|--------|--------|------|
| Base mainnet micro-fixture | Base Builder Rewards/Grant | After failure lab + Builder Code |
| Arc Agent Settlement Assurance | Circle | When portal opens |
| Cloudflare hosted runner | Cloudflare credits | If entity eligible |
| NEAR / Aptos / Tezos / Solana | Various | Only if native fit |

---

## What I would **not** do (per v3)

- Submit grants before lifecycle fix  
- Port Railguard to 10 chains with renamed READMEs  
- Chase maximum grant amounts on first applications  
- Invest in “Railguard” public brand before legal checks  
- Publish under `@x402-guard/*` long term  
- Treat credits as cash revenue  

---

## Recommended immediate next steps (this week)

| # | Action | Repo | Est. |
|---|--------|------|------|
| 1 | Fix `releaseAuthorization` on `unknown` | `coinbase/api.ts` | 1 day |
| 2 | Migration 008 + persist guard correlation | `coinbase/` | 1 day |
| 3 | `verifyTransferFacts()` + reconciler commit path | `coinbase/` | 2–3 days |
| 4 | APF-003 + APF-004 adversarial tests | `coinbase/` | 2 days |
| 5 | Update README + FAILURE_MODES_FIXED | `x402-guard`, `railguard-new` | 0.5 day |
| 6 | Bash `make e2e` + `make failure-lab` | `railguard-new` | 1 day |

**Week 2–3:** Failure lab repo scaffold + first 4 profiles + NLnet/Stellar proposal drafts.

---

## Success metrics (how we know v3 is working)

| Metric | Target |
|--------|--------|
| Lifecycle tests | All 9 adversarial scenarios green |
| Grant readiness | Phase 1 complete before any submission |
| Failure lab | 4–6 profiles with SARIF/JSON output |
| External proof | 1 maintainer running a profile |
| Hiring | Pin failure lab + 3 repos; demo crash-after-broadcast in 3 min |

---

## Bottom line

`v3plan.md` is a grant + hiring operating system, not a feature list. The critical path is:

```text
Fix CDP lifecycle bug (confirmed in code)
  → settlement fact verification
  → adversarial tests
  → portable make/failure-lab
  → Agent Payment Failure Lab
  → NLnet + Stellar applications
  → ecosystem grants after proof
```

The three existing repos are **fixtures and reference implementations** for the failure lab — not three separate products to maintain forever.
