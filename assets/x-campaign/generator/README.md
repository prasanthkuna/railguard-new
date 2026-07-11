# Railguard X slide generator

Design-system PNGs from HTML + Chrome headless (no Figma, no AI).

## Generate all images

```powershell
cd assets/x-campaign/generator
bun install
bun run generate
```

**62 PNGs** → `assets/x-campaign/` (brand, standalone, carousels C01–C08, proofs)

## Pipeline

1. `capture-outputs.ts` — runs `bun test` / `go test`, saves terminal text
2. `build-slides.ts` — builds `slides.html` from design tokens
3. `generate-chrome.ts` — Chrome `--headless=new --screenshot` per slide

## Re-run after copy changes

```powershell
bun run build && bun run generate-chrome.ts
```

## Note

Playwright (`generate.ts`) may hang on some Windows setups. Default is `generate-chrome.ts`.
