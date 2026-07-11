# X Launch — Minimal (9 assets max)

**Philosophy:** Vitalik posts *ideas + one diagram*. CZ posts *one line + proof*. Neither runs 8 carousel campaigns.

Your edge is **audit remediation on money-moving systems** — not graphic design volume.  
**Text carries the argument. Images are anchors, not the product.**

**One link always:** `github.com/prasanthkuna/railguard-new/blob/master/docs/PORTFOLIO.md`

---

## Total: 9 files (not 58)

| # | File | How | Size |
|---|------|-----|------|
| 1 | `pin-one-pager.png` | Generate **1** | 1600×900 |
| 2 | `diagram-boundaries.png` | Generate **1** | 1200×1200 |
| 3 | `proof-x402.png` | **Screenshot** (raw) | any |
| 4 | `proof-forge.png` | **Screenshot** (raw) | any |
| 5–9 | Carousel **optional** — 5 slides only | Generate if you want swipe | 1080×1350 each |

**Minimum viable launch: 4 files** (pin + diagram + 2 terminal shots).  
**Maximum:** 9 files (add 5-slide carousel). **Stop there.**

---

## What to generate (only 2–7 images)

### 1. `pin-one-pager.png` — **PIN THIS** (1600×900)

One image. Everything important. No series.

```text
Title: Agent payments fail on glue, not validators

2×2 grid:
  Mutable ALLOW          Budget TOCTOU
  Post-broadcast lie     FIFO reconcile

Center strip:
  Intent → Policy → Session → Signature → Hook → Receipt → Reconcile

Footer:
  v0.1-reference · reference impl · not mainnet
  github.com/prasanthkuna/railguard-new/blob/master/docs/PORTFOLIO.md
```

Dark bg `#0A0B0D`. No logo required — text is fine.  
**Style:** dense technical one-pager (Vitalik blog header energy), not marketing carousel.

---

### 2. `diagram-boundaries.png` — (1200×1200)

One diagram. Post with tweet #2.

```text
[Agent] → [x402-guard] → [SignGate + Hook] → [CDP + Reconciler] → [Chain]
           blue            purple              cyan

Caption on image (small):
  Pre-sign · Execute · Reconcile
```

Hand-drawn / Excalidraw aesthetic beats polished Figma.

---

### 3–4. Terminal proof — **screenshot, do not AI**

Run once. Post raw. Authenticity > polish.

```powershell
cd x402-guard && bun test packages/policy/src/authorize.test.ts
cd ..\railguard-new\contracts && forge test --match-contract PrdDemo -vv
```

Save as:
- `proof-x402.png`
- `proof-forge.png`

Crop nothing fancy. Windows Terminal dark theme is enough.

---

### 5–9. Optional carousel (5 slides) — only if you want swipe

Folder: `carousels/minimal/`

| File | Content |
|------|---------|
| `01-thesis.png` | **Thesis:** Atomicity + truth convergence. 3-repo stack. v0.1-reference |
| `02-bugs.png` | All 4 bugs on ONE slide (small type OK) |
| `03-fix.png` | All 4 fixes on ONE slide |
| `04-diagram.png` | Same as `diagram-boundaries.png` |
| `05-cta.png` | Portfolio URL + “poke holes in the state machine” |

**Skip** separate carousels for CDP, source-of-truth, honest gaps — that’s **blog/portfolio** content, not X.

---

## What NOT to generate

| Cut | Why |
|-----|-----|
| 46 carousel slides | Agency playbook, not founder credibility |
| Logo / wordmark / avatar ring | CZ doesn’t need it; ship thesis |
| OG / profile banner | Do later in 5 min if account grows |
| 6 terminal shots | 2 proofs enough |
| Remotion / Rotato | Wrong medium |
| AI-polished “fintech” UI mockups | Reads as vapor |

---

## 4 posts total (3 weeks)

### Post 1 — PIN (CZ: one conviction)

**Media:** `pin-one-pager.png`

```text
I audited a 3-repo agent payment stack (x402 + hook + CDP).

The bugs weren't missing validators.
They were atomicity and truth convergence.

4 bugs. 4 fixes. E2E proof.
v0.1-reference — not mainnet production.

↓
```

**Reply to self:** portfolio link only.

---

### Post 2 — Diagram (Vitalik: teach one thing)

**Media:** `diagram-boundaries.png`

```text
Policy has to run in three places:

before sign (x402-guard)
at execution (session + hook)
after broadcast (reconcile to chain)

Miss one boundary → money moves without truth.
```

---

### Post 3 — Proof (show don't tell)

**Media:** `proof-x402.png` + `proof-forge.png` (2 images in one tweet, or thread of 2)

```text
Budget enforcement is a reservation, not a read.

On-chain: one allowed transfer, three blocked attack paths.

Tests green. Reference impl.
```

---

### Post 4 — Honest gaps (Vitalik: trust via limitation)

**Media:** none (text only) OR reuse `pin-one-pager.png`

```text
What v0.1 does NOT claim:

· mainnet-ready custody
· deep reorg rewind
· paymaster / solana / dashboard

What it does claim:

immutable ALLOW facts
atomic budget reservation
executionDigest reconciliation
documented open gaps

If you review payment state machines — poke holes.
```

Link issues #1–#4 in reply.

---

## AI prompt (use for 2 generated images only)

```text
Minimal dark technical one-pager, engineer audience, not marketing.
Background #0A0B0D, white and gray text, small accent blue #3B82F6.
Dense information layout like Vitalik blog or system design sketch.
No 3D, no coins, no rockets, no stock photos, no gradients hype.
Sharp readable typography, high information density.
```

---

## Folder layout

```text
assets/x-campaign/
├── pin-one-pager.png
├── diagram-boundaries.png
├── proof-x402.png
├── proof-forge.png
└── carousels/minimal/          # optional
    ├── 01-thesis.png … 05-cta.png
```

---

## Comparison

| Old plan | This plan |
|----------|-----------|
| 58 PNGs | **4–9** |
| 8 carousels / 3 weeks | **4 posts** |
| Designer / Figma | You + 2 AI images |
| Marketing campaign | **Technical credibility** |

---

## If you only do one thing today

1. Generate **`pin-one-pager.png`**
2. Screenshot **`proof-forge.png`**
3. Pin post 1 + reply with portfolio link

That’s a Vitalik/CZ launch. Everything else is optional.

---

*Extended 58-image manifest retired — see git history if needed.*
