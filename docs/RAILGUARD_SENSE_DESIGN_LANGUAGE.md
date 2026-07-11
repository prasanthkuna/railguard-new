# Railguard Sense — Design Language (Blade-inspired)

**Inspired by:** [RazorSense](https://razorpay.com/razorsense/) (philosophy + motion) and [Blade](https://blade.razorpay.com/) (tokens + components).  
**Not a copy:** We adopt the **architecture**, not Razorpay colors, glyph, or Flutes visuals.

**Use with:** [X_INFOGRAPHIC_ASSET_BRIEF.md](./X_INFOGRAPHIC_ASSET_BRIEF.md)

---

## 1. How RazorSense and Blade fit together

Razorpay splits design into two layers (same pattern many mature fintech systems use):

| Layer | RazorSense | Blade | Railguard equivalent |
|-------|------------|-------|----------------------|
| **Philosophy** | Emotion at every touchpoint (Calm, Joyful, Caution, Regret) | — | **Financial truth states** (see §3) |
| **Brand atom** | Glyph from logo — every angle derives from mark | Theme shell | **Rail mark** — track + shield geometry (§4) |
| **Intelligence** | Flutes — context-aware pulse, “thinking” UI | Thinking state, skeleton, ray loading | **Policy pulse** — agent → policy → reservation (§5) |
| **Implementation** | — | Cards, buttons, insights, progress, success | **Slide surfaces** — 5 masters for X carousels (§6) |
| **Tokens** | Color/form tied to emotion | Abstract semantic tokens → theme values | **`rg.*` tokens** — one name, stable meaning (§7) |

**Key Blade idea to steal:** [semantic token names](https://medium.com/razorpay-design/organising-design-systems-3f191c4e00c0) — e.g. `surface.intent.negative` always means “danger/exploit,” regardless of exact hex. Designers and engineers speak the same language.

**Key RazorSense idea to steal:** **State = feeling.** Payment infra is dry; your carousels win when each slide’s *state* is instantly readable (exploit feels dangerous, fix feels resolved, unknown feels suspended).

---

## 2. What we do NOT import

| Razorpay | Why skip |
|----------|----------|
| Razorpay blue / flute motion | Wrong brand; reads as “I work at Razorpay” |
| Joyful / playful motion on money slides | Undermines audit-serious tone |
| Full Blade React package | Static PNG carousels only for v0.1 |
| Light marketing UI | Railguard = dark, engineer-first |

---

## 3. Railguard truth states (replaces Calm / Joyful / Caution / Regret)

Map RazorSense emotions to **money-moving semantics** — use one state per slide region:

| State ID | RazorSense analog | Meaning | Token intent | Use on slides |
|----------|-------------------|---------|--------------|---------------|
| `truth.calm` | Calm | Invariant / architecture / neutral fact | `intent.neutral` | Pipeline, source-of-truth |
| `truth.resolved` | Joyful | Fix shipped, test PASS, reconciled | `intent.positive` | After column, green terminal |
| `truth.caution` | Caution | Ambiguous: `submitted`, `unknown`, pending | `intent.notice` | Post-broadcast SM |
| `truth.breach` | Regret | Exploit, race, lie, FIFO bug | `intent.negative` | Before column, attack paths |

**Rule:** Every **M2 Exploit → Fix** slide uses `truth.breach` left, `truth.resolved` right. Background stays `bg-primary`; only cards and accents change intent.

---

## 4. The glyph — “born from the rail” (RazorSense core idea)

RazorSense derives corners and motion from the [Razorpay logo glyph](https://razorpay.com/razorsense/). Railguard needs one atomic mark:

```text
Rail mark (designer delivers SVG):
- Vertical track (execution path)
- Horizontal tie (policy gate)
- Optional shield cutout (enforcement)

Derived geometry for ALL surfaces:
- Card corner radius: 8px (soft) or 12px (hero) — consistent
- Divider angle: 4° subtle (optional, from track slope)
- Arrowheads: same stroke width as mark (2px @1x)
```

**Do not** use Razorpay’s “R” flute shapes. **Do** use “one mark → all radii, strokes, arrows align.”

---

## 5. Policy pulse (replaces Flutes)

Flutes = dynamic intelligence layer. For Railguard static infographics, express as **visual rhythm**, not animation:

| Pulse stage | Label | Visual |
|-------------|-------|--------|
| P0 | Intent | Single node, `text-secondary` |
| P1 | Policy eval | Blue pulse ring (`accent-brand` 20% opacity) |
| P2 | Reserved | Solid blue border on node |
| P3 | Executed | Purple (`accent-purple`) |
| P4 | Reconciled | Green check (`accent-trust`) |

Use on **C03 pipeline** and **C04 authorizePayment** — numbered nodes with ring progression, not literal AI blobs.

For optional **GIF** (one only): terminal test output is enough; skip Flute-style motion.

---

## 6. Surfaces (Blade components → slide masters)

Blade documents [CARD, BUTTON, INSIGHTS, SKELETON, THINKING, RAY LOADING, PROGRESS, SUCCESS](https://razorpay.com/razorsense/). Map to carousel components:

| Blade component | Railguard slide component | Spec |
|-----------------|---------------------------|------|
| **Card** | `surface.card.default` | `bg-elevated`, 1px `bg-border`, radius 12px, padding 32px |
| **Card** (highlight) | `surface.card.emphasis` | Left border 4px = intent color |
| **Insights** | `surface.insight.quote` | Italic quote + intent left bar (M2 bottom) |
| **Button** (primary) | `surface.cta.primary` | Filled `accent-brand`, text `bg-primary` — CTA slide only |
| **Button** (ghost) | `surface.cta.ghost` | Border `bg-border`, text `text-primary` — repo pills |
| **Progress** | `surface.flow.step` | Numbered circles ①②③④, connector 2px |
| **Success state** | `surface.proof.pass` | Green badge + terminal crop frame |
| **Thinking state** | `surface.state.unknown` | Dashed border `accent-warn`, label `unknown` |
| **Skeleton** | — | **Do not use** on X (looks unfinished) |

---

## 7. Token architecture (Blade-style JSON)

Three tiers — same as Blade theme mapping:

```json
{
  "primitive": {
    "color.blue.500": "#3B82F6",
    "color.purple.500": "#A78BFA",
    "color.cyan.500": "#22D3EE",
    "color.green.500": "#22C55E",
    "color.red.500": "#EF4444",
    "color.amber.500": "#F59E0B",
    "color.zinc.950": "#0A0B0D",
    "color.zinc.900": "#14161A",
    "color.zinc.700": "#2A2D35",
    "color.zinc.100": "#F4F4F5",
    "color.zinc.400": "#A1A1AA"
  },
  "semantic": {
    "bg.primary": "{color.zinc.950}",
    "bg.elevated": "{color.zinc.900}",
    "border.default": "{color.zinc.700}",
    "text.primary": "{color.zinc.100}",
    "text.secondary": "{color.zinc.400}",
    "intent.neutral": "{color.zinc.400}",
    "intent.positive": "{color.green.500}",
    "intent.negative": "{color.red.500}",
    "intent.notice": "{color.amber.500}",
    "boundary.x402": "{color.blue.500}",
    "boundary.signgate": "{color.purple.500}",
    "boundary.cdp": "{color.cyan.500}"
  },
  "component": {
    "surface.card.default.bg": "{bg.elevated}",
    "surface.card.default.border": "{border.default}",
    "surface.card.exploit.border": "{intent.negative}",
    "surface.card.fix.border": "{intent.positive}",
    "surface.insight.quote.border": "{boundary.x402}",
    "surface.state.unknown.border": "{intent.notice}",
    "surface.proof.pass.badge": "{intent.positive}"
  }
}
```

**Figma setup:** Create variables collection `primitive` → alias to `semantic` → alias to `component`. Matches [Blade’s theme playground](https://blade.razorpay.com/?path=/docs/guides-theming-theme-playground--docs) pattern.

---

## 8. Typography & spacing (Blade-aligned naming)

| Token | Value |
|-------|-------|
| `font.heading` | Inter 700 |
| `font.body` | Inter 400 |
| `font.code` | JetBrains Mono 400 |
| `space.page` | 80px |
| `space.card` | 32px |
| `space.stack.sm` | 16px |
| `space.stack.md` | 24px |
| `radius.sm` | 8px |
| `radius.md` | 12px |
| `stroke.icon` | 1.5px |
| `stroke.connector` | 2px |

---

## 9. Applying to X carousels (practical)

### Cover slide (M1)
- `bg.primary` + subtle grid at 4% opacity
- `truth.calm` — no red/green yet
- Rail mark + wordmark
- Title uses `font.heading`; subtitle `text.secondary`

### Bug slides (M2)
```
┌─────────────────────────────────────┐
│  [truth.breach card]  →  [truth.resolved card]  │
│  surface.card.exploit    surface.card.fix        │
│  ─────────────────────────────────────────────  │
│  surface.insight.quote (canonical quote)         │
└─────────────────────────────────────┘
```

### Boundary slides (C02)
- Each repo = `surface.card.default` + top stripe 4px in `boundary.*` color
- Never mix boundary colors on one card

### C05 post-broadcast
- State nodes use `surface.state.unknown` for `unknown` / `submitted`
- Terminal proof uses `surface.proof.pass`

### CTA slide (M5)
- One `surface.cta.primary` block with portfolio URL
- Three `surface.cta.ghost` pills: x402-guard · railguard-new · railguard-cdp

---

## 10. Designer checklist (RazorSense quality bar)

- [ ] Every slide has exactly **one** dominant `truth.*` state
- [ ] All corners/strokes trace back to **rail mark** spec (§4)
- [ ] Colors applied via **semantic tokens**, not raw hex in components
- [ ] Exploit/fix pairs always **breach → resolved** (never both red)
- [ ] `unknown` / caution uses **amber**, not red (RazorSense Caution ≠ Regret)
- [ ] No skeleton loaders on published slides
- [ ] Footer: `v0.1-reference` on every slide

---

## 11. Optional: name the system in outreach

One line for X bio or pin:

> **Railguard Sense** — financial truth states for agent payments. v0.1-reference.

Positions you as someone who thinks in **design systems + money-moving semantics**, not just code dumps.

---

## 12. Files to deliver (images only)

| File | Purpose |
|------|---------|
| [X_IMAGE_MANIFEST.md](./X_IMAGE_MANIFEST.md) | **58 PNG checklist** |
| `assets/x-campaign/design-system/railguard-tokens.json` | Color reference |
| `assets/x-campaign/brand/logo-mark-512.png` | Logo |
| `assets/x-campaign/carousels/**/*.png` | All slides |

---

*References: [RazorSense](https://razorpay.com/razorsense/) · [Blade Storybook](https://blade.razorpay.com/) · [Blade GitHub](https://github.com/razorpay/blade/) · [Organising Design Systems (Razorpay)](https://medium.com/razorpay-design/organising-design-systems-3f191c4e00c0)*
