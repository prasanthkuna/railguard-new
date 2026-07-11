# GitHub profile setup (2 minutes)

Repos and README visuals are pushed. **Pinning + bio** need one manual step (GitHub has no pin API).

## 1. Pin these 3 repos (in order)

1. Open https://github.com/prasanthkuna
2. **Customize your pins**
3. Pin (top → bottom):

| Order | Repo |
|-------|------|
| 1 | [railguard-new](https://github.com/prasanthkuna/railguard-new) |
| 2 | [x402-guard](https://github.com/prasanthkuna/x402-guard) |
| 3 | [railguard-cdp](https://github.com/prasanthkuna/railguard-cdp) |

4. **Save pins**

## 2. Profile bio (copy-paste)

**Bio:**
```text
Money-moving infra for AI agent payments — x402 policy, SignGate, on-chain hooks, CDP reconciliation. Railguard v0.1-reference.
```

**Website:**
```text
https://github.com/prasanthkuna/railguard-new/blob/master/docs/PORTFOLIO.md
```

**X / Twitter:** `@prasanth_kuna`

Edit: https://github.com/settings/profile

## 3. Optional — enable bio via CLI

If `gh` lacks `user` scope, complete device login then:

```powershell
gh auth refresh -h github.com -s user
gh api user --method PATCH -f bio="Money-moving infra for AI agent payments — x402 policy, SignGate, on-chain hooks, CDP reconciliation. Railguard v0.1-reference." -f blog="https://github.com/prasanthkuna/railguard-new/blob/master/docs/PORTFOLIO.md" -f twitter_username="prasanth_kuna"
```

## What visitors see now

- **railguard-new README:** pin one-pager + architecture diagram
- **x402-guard / railguard-cdp README:** shared diagram → PORTFOLIO
- **Regenerate slides:** `cd assets/x-campaign/generator && bun run generate`
