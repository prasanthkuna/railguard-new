# External review requests

Copy each section into a GitHub issue (or discussion) when reaching out to x402, Base, Safe, or payments engineers.

**Created on railguard-new:**

| # | Issue |
|---|-------|
| 1 | https://github.com/prasanthkuna/railguard-new/issues/1 — x402 `authorizePayment` |
| 2 | https://github.com/prasanthkuna/railguard-new/issues/2 — `executionDigest` reconciliation |
| 3 | https://github.com/prasanthkuna/railguard-new/issues/3 — CDP post-broadcast state |
| 4 | https://github.com/prasanthkuna/railguard-new/issues/4 — failure modes table |

**Upstream:** Comment posted on [mark3labs/x402-go#26](https://github.com/mark3labs/x402-go/issues/26#issuecomment-4945323752).

**Ask:** “Can you poke holes in this state machine?” — not “please star my repo.”

---

## Issue 1: x402 replay / budget authorization

**Title:** Request for review: atomic `authorizePayment` (replay + budget reservation)

**Body:**

```markdown
## Context

[x402-guard](https://github.com/prasanthkuna/x402-guard) v0.1-reference implements pre-sign policy for agent payments.

## Model

1. `claimReplay(fingerprint)` — atomic
2. `reserveBudget(agent, amount, windows, authorizationId)` — atomic
3. Callback / payment runs
4. `commitAuthorization` or `releaseAuthorization`

## Questions

- Is reservation-before-callback the right primitive for x402 middleware?
- Should authorization handles be standardized across implementations?
- Gaps in rolling-window semantics?

## Proof

`bun test packages/policy/src/authorize.test.ts packages/policy/src/fault-injection.test.ts`

Portfolio: https://github.com/prasanthkuna/railguard-new/blob/master/docs/PORTFOLIO.md
```

---

## Issue 2: executionDigest reconciliation

**Title:** Request for review: off-chain reconciliation by `executionDigest` (not FIFO)

**Body:**

```markdown
## Context

[railguard-new](https://github.com/prasanthkuna/railguard-new) watcher ingests `ExecutionAllowed(account, executionDigest, ...)`.

Previously: oldest pending reservation per session (FIFO).
Now: match `executionDigest` to reservation / chain_executions row.

## Questions

- Is digest-per-execution sufficient without full UserOp hash in v1?
- Reorg handling with block-hash cursor only?

## Proof

`powershell -File scripts/e2e-happy-path.ps1` (Docker + Foundry)

Failure modes: https://github.com/prasanthkuna/railguard-new/blob/master/docs/FAILURE_MODES_FIXED.md
```

---

## Issue 3: Post-broadcast payment state

**Title:** Request for review: CDP payment state after broadcast

**Body:**

```markdown
## Context

[railguard-cdp](https://github.com/prasanthkuna/railguard-cdp) — after CDP returns tx hash, DB/audit failures must not set status `failed`.

States: `submitted` / `unknown` until reconciler + receipt `status === success`.

## Questions

- Missing terminal states?
- Reconciler frequency / idempotency?

## Proof

`bun test apps/api/payment-state.test.ts`
```

---

## Issue 4: Failure modes table

**Title:** Request for review: Railguard v0.1 failure modes + fixes

**Body:**

```markdown
Please review the failure-mode table for blind spots:

https://github.com/prasanthkuna/railguard-new/blob/master/docs/FAILURE_MODES_FIXED.md

Tag: v0.1-reference across all three repos.
```

---

## Where to post

- x402 GitHub discussions / issues (policy middleware gap)
- Base / Coinbase developer community
- Safe / Rhinestone / ZeroDev channels (session + hook model)
- Personal outreach with PORTFOLIO.md link only
