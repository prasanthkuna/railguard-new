# Upstream contribution (pick one)

Do **not** upstream the full Railguard system. One small, high-signal contribution.

---

## Option A — x402 policy middleware example (recommended)

**Target:** x402 ecosystem docs or `x402-go` / foundation examples

**Payload:** Minimal middleware pseudocode showing:

```text
authorizePayment → sign → commit | release on failure
```

**Source:** `x402-guard/packages/middleware/src/index.ts` + link to PORTFOLIO.md

**Effort:** README + 30-line example PR

---

## Option B — Issue comment on spending policy gap

**Target:** [mark3labs/x402-go#26](https://github.com/mark3labs/x402-go/issues/26) or [x402-foundation/x402#2294](https://github.com/x402-foundation/x402/issues/2294)

**Comment draft:**

> I built a reference implementation of pre-sign spending policy + atomic budget reservation for agent payments (replay claim, rolling windows, commit/release): https://github.com/prasanthkuna/x402-guard (tag v0.1-reference). Happy to align on a minimal middleware interface if useful — not proposing a full standard, just sharing patterns from audit remediation.

---

## Option C — Base Sepolia demo note

**Target:** Base docs or dev forum

**Payload:** Link to `e2e-happy-path.ps1` as “policy + hook + watcher” local demo on Anvil chain-id 84532.

---

## Option D — Safe/Rhinestone session hook pattern

**Target:** Community forum / issue

**Payload:** Link to `PrdDemo.t.sol` + hook `executionDigest` event — session-scoped USDC transfer enforcement only.

---

**Pick one.** Ship within a week of v0.1-reference tag.
