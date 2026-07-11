# Interview openers (rehearse)

## 30 seconds (use exactly, then stop)

> Railguard is a v0.1 reference implementation for policy-enforced AI-agent stablecoin payments. I focused on the failure modes that make money-moving systems dangerous: mutable approvals, read-then-write budget races, post-broadcast state lies, and off-chain/on-chain reconciliation drift. The stack has three boundaries: x402-guard before signing, Railguard sessions and hook at execution, and CDP invoice reconciliation after broadcast.

---

## 3 minutes

Add after 30s:

1. **Immutable intent hash** — C-01 story (30s)
2. **authorizePayment** — reservation primitive (30s)
3. **broadcastedTxHash** — never failed after broadcast (30s)
4. **executionDigest** — not FIFO (30s)
5. **Demo offer** — PrdDemo or x402 test (30s)

---

## 10 minutes

1. Draw invariant: Intent → Policy → Session → Signature → Hook → Receipt → Reconcile
2. Source-of-truth table from [PORTFOLIO.md](./PORTFOLIO.md)
3. Run `forge test --match-contract PrdDemo -vv` OR `bun test packages/policy/src/authorize.test.ts`
4. Honest limitations — reorg, HSM, integration fault-injection
5. Q&A

---

## STAR stories (quick reference)

| Story | Finding | Fix |
|-------|---------|-----|
| A | x402 budget TOCTOU | `authorizePayment` |
| B | Post-broadcast double-pay | `unknown` + reconciler |
| C | FIFO watcher | `executionDigest` |
| D | CI / E2E proof | lockfile, Docker migrations |

Full detail: [THREE_PROJECT_IMPROVEMENTS_AND_INTERVIEW_PREP.md](./THREE_PROJECT_IMPROVEMENTS_AND_INTERVIEW_PREP.md)

---

## Role-specific pitches

| Team | Doc |
|------|-----|
| Coinbase / Base | [PITCH_COINBASE_BASE.md](./PITCH_COINBASE_BASE.md) |
| Fireblocks / policy | [PITCH_FIREBLOCKS.md](./PITCH_FIREBLOCKS.md) |
| Safe / Rhinestone | [PITCH_SAFE_RHINESTONE.md](./PITCH_SAFE_RHINESTONE.md) |
| Backend / platform | [PITCH_BACKEND_PLATFORM.md](./PITCH_BACKEND_PLATFORM.md) |

---

## Before every interview

```powershell
cd x402-guard && bun test packages/policy/src/authorize.test.ts
# OR
cd railguard-new\contracts && forge test --match-contract PrdDemo -vv
```
