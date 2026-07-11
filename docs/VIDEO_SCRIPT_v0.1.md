# Video script — Railguard v0.1 (5 minutes)

**Title:** Railguard v0.1: Policy-Enforced AI Agent Stablecoin Payments

Record screen + voiceover. Do not exceed 5 minutes.

---

## 0:00 — Problem (40s)

> AI agents will pay vendors and APIs with stablecoins and x402. Signing a payment is easy. The hard part is making sure policy, budgets, and what actually moved on-chain stay aligned — especially when databases fail after broadcast.

Show: PORTFOLIO.md invariant line.

---

## 1:30 — Architecture (30s)

> Railguard has three enforcement boundaries: x402-guard before signing, SignGate and an on-chain hook at execution, and a CDP invoice path with reconciliation after broadcast.

Show: THREE_PROJECT_SYSTEM_DIAGRAM.md (scroll slowly).

---

## 2:00 — x402 atomic authorization (50s)

```powershell
cd x402-guard
bun test packages/policy/src/authorize.test.ts
bun test packages/policy/src/fault-injection.test.ts
```

> Budget enforcement is a reservation, not a read. Replay and rolling windows are atomic.

---

## 2:50 — On-chain attack demo (50s)

```powershell
cd railguard-new\contracts
forge test --match-contract PrdDemo -vv
```

> One allowed transfer, three blocked attack paths. The hook is the physical safety boundary.

---

## 3:40 — CDP state machine (40s)

```powershell
cd coinbase
bun test apps/api/payment-state.test.ts
```

> After broadcast, we never mark failed. Ambiguous states stay submitted or unknown until reconciliation.

---

## 4:20 — Honest gaps (40s)

Show: PORTFOLIO.md known limitations.

> v0.1 reference implementation — not mainnet production. Gaps: deep reorg rewind, HSM key custody, full integration fault-injection. Documented on purpose.

---

## 4:50 — Close (10s)

> Portfolio link in description. Tag v0.1-reference on all three repos.

**Description link:** `https://github.com/prasanthkuna/railguard-new/blob/master/docs/PORTFOLIO.md`
