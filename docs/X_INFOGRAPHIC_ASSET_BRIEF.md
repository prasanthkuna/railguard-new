# X / Infographic Asset Brief — Railguard v0.1

**Minimal launch (Vitalik/CZ style):** **[X_IMAGE_MANIFEST.md](./X_IMAGE_MANIFEST.md)** — **4–9 images**, 4 posts. Not 58.

**Philosophy:** Text carries the argument. One pin image + one diagram + raw terminal proof. No carousel campaign.

**You deliver:** 2 generated PNGs + 2 terminal screenshots (+ optional 5-slide carousel).

**Portfolio link:** `https://github.com/prasanthkuna/railguard-new/blob/master/docs/PORTFOLIO.md`

**Design tokens (optional):** `assets/x-campaign/design-system/railguard-tokens.json` · [RAILGUARD_SENSE_DESIGN_LANGUAGE.md](./RAILGUARD_SENSE_DESIGN_LANGUAGE.md)

---

## 1. Image inventory (minimal)

| File | Size | Required? |
|------|------|-----------|
| `pin-one-pager.png` | 1600×900 | **Yes — pin** |
| `diagram-boundaries.png` | 1200×1200 | **Yes** |
| `proof-x402.png` | screenshot | **Yes** |
| `proof-forge.png` | screenshot | **Yes** |
| `carousels/minimal/01–05.png` | 1080×1350 | Optional |

**Full spec + tweet copy:** [X_IMAGE_MANIFEST.md](./X_IMAGE_MANIFEST.md)

---

## 2. Core Narrative & Target Hook

The narrative centers on **technical depth and vulnerability remediation in money-moving systems**, appealing directly to smart contract, platform, and security engineers.

* **The Hook:** AI agent payments fail on the integration glue, not on-chain validators.
* **The Core Thesis:** Cryptographic signatures and validation are necessary but insufficient. If state transitions, budget locks, and watcher reconcilers are not atomic and bound to immutable facts, agent systems will leak funds.
* **Tone:** High-density, engineering-first, transparent about limitations (no marketing hyperbole).
* **Target Audience:** protocol designers, smart-contract developers, security auditors, web3 founders.

---

## 3. Design system

### 3.1 Canvas sizes

| Asset | Pixels | Ratio | Notes |
|-------|--------|-------|-------|
| Carousel slide | **1080 × 1350** | 4:5 | X carousel standard; max readability mobile |
| Single wide image | **1600 × 900** | 16:9 | Pin tweet, LinkedIn |
| Profile banner | **1500 × 500** | 3:1 | Safe zone: center 1280×400 |
| OG image | **1200 × 630** | ~1.91:1 | GitHub / blog |
| Terminal crop | **1080 × 1350** | 4:5 | Crop from 1920×1080 with 80px padding |

**Export:** PNG only, sRGB. Publish **1080×1350** for carousels.

### 3.2 Color tokens

> **Full token file:** `assets/x-campaign/design-system/railguard-tokens.json`  
> **Philosophy:** [RAILGUARD_SENSE_DESIGN_LANGUAGE.md](./RAILGUARD_SENSE_DESIGN_LANGUAGE.md) — map RazorSense emotions → `truth.calm | resolved | caution | breach`

| Token | Hex | Use |
|-------|-----|-----|
| `bg-primary` | `#0A0B0D` | Slide background |
| `bg-elevated` | `#14161A` | Cards, code blocks |
| `bg-border` | `#2A2D35` | Dividers, box strokes |
| `text-primary` | `#F4F4F5` | Headlines, body |
| `text-secondary` | `#A1A1AA` | Captions, footers |
| `accent-brand` | `#3B82F6` | Railguard / links / boundary #1 |
| `accent-trust` | `#22C55E` | Fixes, PASS, allowed |
| `accent-danger` | `#EF4444` | Exploits, BLOCK, race |
| `accent-warn` | `#F59E0B` | `unknown` / `submitted` states |
| `accent-purple` | `#A78BFA` | Boundary #2 (on-chain) |
| `accent-cyan` | `#22D3EE` | Boundary #3 (CDP) |

**Gradient (cover only):** `#0A0B0D` → `#14161A` diagonal 135°, 8% opacity blue glow top-right.

### 3.3 Typography

| Role | Font | Weight | Size (1080×1350) |
|------|------|--------|------------------|
| Slide title | **Inter** | 700 | 56–64px |
| Section label | Inter | 600 | 28px, uppercase, letter-spacing 0.08em |
| Body | Inter | 400 | 32–36px, line-height 1.35 |
| Quote / principle | Inter | 500 italic | 34px, left border 4px `accent-brand` |
| Code / API | **JetBrains Mono** | 400 | 26–28px |
| Footer | Inter | 500 | 22px `text-secondary` |
| Slide number | JetBrains Mono | 400 | 24px top-right `text-secondary` |

**Max words per slide:** 35 (headline + 2 bullets). ByteByteGo rule: one idea per slide.

### 3.4 Layout grid (1080×1350)

```text
Margins: 80px all sides
Header zone: y 80–200 (title + optional eyebrow)
Content zone: y 200–1150
Footer zone: y 1150–1270 (tag + slide N/M)
```

### 3.5 Slide layouts (reference for image generation)

| Layout | Use on slides |
|--------|----------------|
| **Cover** | Eyebrow, big title, subtitle, logo mark bottom-left |
| **Exploit → Fix** | Red “Before” column, green “After” column, center arrow, quote bar bottom |
| **Flow diagram** | 3–5 numbered boxes, mono labels |
| **Table** | 2 columns, max 6 rows |
| **CTA** | Title, portfolio URL, three repo pills |

**Recurring chrome (every carousel slide):**
- Top-left: small logo mark
- Top-right: slide counter e.g. `03 / 07`
- Bottom: `Railguard v0.1-reference`

### 3.6 Iconography

Use **Lucide** or **Phosphor** (stroke 1.5px, 48px):

| Concept | Icon |
|---------|------|
| Agent | `bot` |
| Policy | `shield-check` |
| Budget | `wallet` |
| Chain | `link-2` |
| Block | `ban` |
| Reconcile | `git-merge` |
| Audit | `list-checks` |

**Do not use:** 3D coins, rocket emojis, “Web3” gradients, stock photos.

### 3.7 Repo boundary colors (consistent everywhere)

| Repo | Color | Label |
|------|-------|-------|
| x402-guard | `accent-brand` blue | Pre-sign policy |
| railguard-new | `accent-purple` | Session + hook |
| railguard-cdp | `accent-cyan` | Broadcast + reconcile |

---

## 4. Brand images

| Filename | Size | Specification |
|----------|------|---------------|
| `brand/logo-mark-512.png` | 512×512 | A minimal geometric icon featuring a vertical execution rail track intersected by a horizontal policy tie. Styled in `accent-brand` (#3B82F6), transparent background. |
| `brand/logo-wordmark-1200x400.png` | 1200×400 | The geometric rail logo mark on the left, followed by the text "Railguard" in Inter bold (white) and "v0.1-reference" in JetBrains Mono (`text-secondary`), on `#0A0B0D` background. |

### Footer Details (Text-only)
* **Display Name:** Prashanth Kuna
* **X Handle:** [@prasanth_kuna](https://x.com/prasanth_kuna)

## 5. Screenshots — what you capture (terminal proof)

These make the campaign credible. **Dark terminal preferred** (Windows Terminal / VS Code theme: One Dark Pro or similar).

### Capture settings

- Resolution: **1920×1080** minimum
- Font: Cascadia Code or JetBrains Mono **14–16pt**
- Hide paths with personal usernames if desired; keep repo names visible
- Run commands fresh so timestamps look current

### Required captures

| ID | Command | Filename | Used in |
|----|---------|----------|---------|
| S1 | `cd x402-guard && bun test packages/policy/src/authorize.test.ts` | `terminal-x402-authorize.png` | C04, pin |
| S2 | `cd x402-guard && bun test packages/policy/src/fault-injection.test.ts` | `terminal-x402-fault.png` | C04 |
| S3 | `cd railguard-new/contracts && forge test --match-contract PrdDemo -vv` | `terminal-forge-prddemo.png` | C02, C06, pin |
| S4 | `cd coinbase && bun test apps/api/payment-state.test.ts` | `terminal-cdp-payment-state.png` | C05 |
| S5 | `cd railguard-new && powershell -File .\scripts\e2e-happy-path.ps1` (last 30 lines, PASS) | `terminal-e2e-happy-path.png` | C08, pin |
| S6 | `cd railguard-new/signgate && go test ./internal/intent -run TestHashIncludesLimits -v` | `terminal-intent-hash.png` | C01 slide 3 |

**Treatment on slides:** Crop to 1080×1350, dark border, optional green PASS badge.

### Optional video (one only)

- **15s max** screen recording of S3 or S1 tests → MP4 for X (not required)

---

## 6. Diagrams (embedded in carousel PNGs — no separate files)

Diagrams are **part of** these manifest slides (not extra exports):

| Diagram | Slide file |
|---------|------------|
| Three boundaries | `C02-three-boundaries/05-diagram-architecture.png` |
| Invariant pipeline | `C03-invariant-pipeline/02-pipeline.png` |
| authorizePayment flow | `C04-authorize-payment/02-flow.png` |
| Post-broadcast SM | `C05-post-broadcast/02-state-machine.png` |
| FIFO vs digest | `C06-execution-digest/02-fifo-vs-digest.png` |
| Source of truth table | `C07-source-of-truth/02–04-table-*.png` |

---

## 7. Carousel copy (detail)

**Per-file checklist with exact text:** [X_IMAGE_MANIFEST.md](./X_IMAGE_MANIFEST.md) §D–K.

Summary below retained for context.

### C01 — Four bugs that make agent payments dangerous (7 slides) **PIN THIS**

| Slide | Master | Copy |
|-------|--------|------|
| 01 | M1 | **Eyebrow:** Security audit · v0.1 · **Title:** 4 bugs in agent payment stacks · **Subtitle:** Atomicity and truth convergence — not missing validators |
| 02 | M3 | **Title:** The invariant · `Intent → Policy → Session → Signature → Hook → Receipt → Reconcile` |
| 03 | M2 | **Bug 1 — Mutable ALLOW** · Before: limits excluded from intent hash · After: canonical hash + immutable persist · Quote: *Authorization only matters if approved facts cannot change.* |
| 04 | M2 | **Bug 2 — Budget TOCTOU** · Before: read → pay → record · After: `authorizePayment` reserve/commit · Quote: *Budget enforcement is a reservation, not a read.* |
| 05 | M2 | **Bug 3 — Post-broadcast lie** · Before: DB fails → status `failed` · After: `unknown` + reconciler · Quote: *Exception text is not financial truth.* |
| 06 | M2 | **Bug 4 — FIFO reconcile** · Before: oldest reservation · After: `executionDigest` match · Quote: *Reconcile by identity, not queue position.* |
| 07 | M5 | **Review the state machine** · github.com/prasanthkuna/railguard-new/blob/master/docs/PORTFOLIO.md · Tags: `v0.1-reference` on 3 repos |

**X post copy:**

```text
I audited a 3-repo agent payment stack (x402 + smart-account hook + CDP).

The bugs weren't missing validators — they were atomicity and truth convergence.

4 bugs → 4 fixes → E2E proof (swipe)

v0.1-reference · link in reply
```

---

### C02 — Three enforcement boundaries (6 slides)

| Slide | Copy |
|-------|------|
| 01 | **Title:** Three repos · Three enforcement boundaries |
| 02 | **Boundary 1** · x402-guard · Pre-sign policy · `authorizePayment` · blue |
| 03 | **Boundary 2** · railguard-new · SignGate + on-chain hook · session caps · purple |
| 04 | **Boundary 3** · railguard-cdp · Invoice + CDP broadcast + reconciler · cyan |
| 05 | Diagram D1 full bleed |
| 06 | M5 CTA |

**X post:** *Where does policy run? Before sign, at execution, and after broadcast. Three boundaries — one portfolio.*

---

### C03 — The pipeline (5 slides)

| Slide | Copy |
|-------|------|
| 01 | **Title:** One payment, seven checkpoints |
| 02 | D2 invariant — large |
| 03 | **Policy intelligence ≠ asset safety** · OPA decides · Hook enforces · Reconciler converges |
| 04 | **CDP vs hook** · CDP = invoice workflow + broadcast truth · Hook = smart-account physical ceiling |
| 05 | M5 CTA |

---

### C04 — `authorizePayment` deep dive (6 slides)

| Slide | Copy |
|-------|------|
| 01 | **Title:** x402 budget enforcement · **Subtitle:** One primitive, four steps |
| 02 | D3 flow diagram |
| 03 | **Replay** · `claimReplay` is atomic — not `hasReplay` then `markReplay` |
| 04 | **Windows** · Rolling limits · reserve before callback · commit or release |
| 05 | Screenshot S1 (+ optional S2 small inset) |
| 06 | M5 · Proof: `bun test packages/policy/src/authorize.test.ts` |

**X post:** *Budget enforcement is not a read — it is a reservation.*

---

### C05 — Post-broadcast state machine (6 slides)

| Slide | Copy |
|-------|------|
| 01 | **Title:** After CDP returns a tx hash · **Subtitle:** Exception text is not financial truth |
| 02 | D4 state machine |
| 03 | **Rule** · If `broadcastedTxHash` exists → never mark `failed` on DB error |
| 04 | **Ambiguous** · `submitted` / `unknown` until reconciler + receipt |
| 05 | Screenshot S4 |
| 06 | M5 |

---

### C06 — `executionDigest` (5 slides)

| Slide | Copy |
|-------|------|
| 01 | **Title:** Reconcile by identity · **Subtitle:** Not FIFO |
| 02 | D5 side-by-side |
| 03 | **On-chain** · `ExecutionAllowed(account, executionDigest, …)` |
| 04 | Screenshot S3 (Forge PrdDemo — attacks blocked) |
| 05 | M5 |

---

### C07 — Source of truth (6 slides)

| Slide | Copy |
|-------|------|
| 01 | **Title:** Who owns financial truth? |
| 02–04 | Split D6 table across 3 slides (2–3 rows each) |
| 05 | **Rule of thumb** · Terminal states converge to chain evidence |
| 06 | M5 |

---

### C08 — Honest gaps (5 slides) **TRUST BUILDER**

| Slide | Copy |
|-------|------|
| 01 | **Title:** v0.1 reference implementation · **Subtitle:** What I did not ship |
| 02 | **Open:** Deep reorg rewind · HSM/MPC cosigners · Postgres fault-injection at API boundary |
| 03 | **Not in v0.1:** Paymaster · Solana · multi-chain · dashboard · mainnet funds |
| 04 | Screenshot S5 E2E PASS |
| 05 | M5 · *If you review money-moving systems — poke holes in the state machine* · link to issues #1–#4 |

**X post:** *Not production-ready for mainnet. Gaps documented on purpose. Swipe for what’s still open.*

---

## 8. Standalone assets

### Pin hero (`pin-hero-1600x900.png`)

```text
Left: Title "Railguard v0.1-reference"
Sub: Policy-enforced AI agent stablecoin payments
Center: D2 invariant pipeline (smaller)
Right: 2×2 grid of four bug titles
Bottom: PORTFOLIO URL
```

### Profile banner (`profile-banner-1500x500.png`)

```text
Center-safe text: Railguard · v0.1-reference
Sub: x402 policy · on-chain hook · CDP reconciliation
Background: subtle grid, no clutter at edges (mobile crops)
```

### OG image (`og-1200x630.png`)

For GitHub social preview / blog:

```text
Railguard v0.1-reference
4 bugs fixed · E2E proof · honest gaps
```

---

## 9. Posting calendar (first 3 weeks)

| Week | Post | Carousel | Pin? |
|------|------|----------|------|
| 1 Mon | Launch | C01 | **Pin** |
| 1 Thu | Architecture | C02 | |
| 2 Mon | Pipeline | C03 | |
| 2 Thu | x402 | C04 | |
| 3 Mon | CDP state | C05 | |
| 3 Thu | executionDigest | C06 | |
| 4 Mon | Source of truth | C07 | |
| 4 Thu | Honest gaps | C08 | |

**Between carousels:** Reply to your own pin with terminal GIF (S3 or S1) once.

**Do not:** Post all 8 in one day. Spacing = credibility.

---

## 10. Quality checklist (before publish)

- [ ] All text readable on **phone** (squint test)
- [ ] Footer on every slide: `v0.1-reference`
- [ ] No “production-ready” or “bank-grade” claims
- [ ] Portfolio URL spelled correctly (no broken line breaks)
- [ ] Slide numbers correct per carousel
- [ ] Repo boundary colors consistent (blue / purple / cyan)
- [ ] Terminal screenshots show green PASS
- [ ] File size **< 5 MB per PNG** (use TinyPNG if needed)
- [ ] Carousel order uploaded **01 → N** in X composer
- [ ] Link in **reply** to main tweet (algorithm habit)

---

## 11. What NOT to build

| Skip | Why |
|------|-----|
| Remotion invoice/fraud video | Wrong hiring narrative |
| Rotato MacBook mockups | Product demo, not infra story |
| Dashboard UI screenshots | v0.1 scope freeze |
| 20-carousel series | Diminishing returns |
| Meme formats | Undermines money-moving credibility |

---

## 12. Image generation handoff

> Generate **58 PNG files** per [X_IMAGE_MANIFEST.md](./X_IMAGE_MANIFEST.md). Use style prompt in manifest §L. No Figma required.

**Reference tone:** ByteByteGo carousels — dark, one idea per slide, exploit→fix layouts.

---

## 13. After images are ready

1. Drop PNGs into `assets/x-campaign/` per manifest
2. Pin C01 on X with `standalone/pin-hero-1600x900.png` optional
3. Post per calendar in manifest §O

---

## Quick reference — canonical quotes (use verbatim)

| Topic | Quote |
|-------|-------|
| ALLOW | Authorization only matters if approved facts cannot change. |
| Budget | Budget enforcement is a reservation, not a read. |
| Broadcast | Exception text is not financial truth. |
| Reconcile | Reconcile by identity, not queue position. |
| Stack | I hardened the glue: immutable ALLOW facts, budget reservations, chain-backed reconciliation. |

---

*Last updated: 2026-07-11 · aligns with `v0.1-reference` scope freeze*
