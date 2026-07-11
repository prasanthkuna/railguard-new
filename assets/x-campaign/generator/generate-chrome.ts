import { readFile, writeFile, mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { homedir } from "node:os";

const __dir = dirname(fileURLToPath(import.meta.url));
const root = join(__dir, "..");
const slidesHtml = join(__dir, "slides.html");
const slidesDir = join(__dir, "slides-out");

const chromeCandidates = [
  "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
  join(homedir(), "AppData/Local/ms-playwright/chromium-1228/chrome-win64/chrome.exe"),
];

const chrome = chromeCandidates.find((p) => existsSync(p));
if (!chrome) throw new Error("Chrome/Edge not found");

type Slide = { id: string; out: string; w: number; h: number };

const slides: Slide[] = [
  { id: "brand-logo-mark", out: "brand/logo-mark-512.png", w: 512, h: 512 },
  { id: "brand-wordmark", out: "brand/logo-wordmark-1200x400.png", w: 1200, h: 400 },
  { id: "pin-one-pager", out: "pin-one-pager.png", w: 1600, h: 900 },
  { id: "pin-hero", out: "standalone/pin-hero-1600x900.png", w: 1600, h: 900 },
  { id: "profile-banner", out: "standalone/profile-banner-1500x500.png", w: 1500, h: 500 },
  { id: "og-image", out: "standalone/og-1200x630.png", w: 1200, h: 630 },
  { id: "diagram-boundaries", out: "diagram-boundaries.png", w: 1200, h: 1200 },
  { id: "proof-x402", out: "proof-x402.png", w: 1600, h: 900 },
  { id: "proof-forge", out: "proof-forge.png", w: 1600, h: 900 },
  { id: "proof-cdp", out: "screenshots/terminal-cdp-payment-state.png", w: 1080, h: 1350 },
  { id: "proof-intent", out: "screenshots/terminal-intent-hash.png", w: 1080, h: 1350 },
  ...["01-thesis", "02-bugs", "03-fix", "04-diagram", "05-cta"].map((s, i) => ({
    id: `min-${String(i + 1).padStart(2, "0")}`,
    out: `carousels/minimal/${s}.png`,
    w: 1080,
    h: 1350,
  })),
  ...["01-cover", "02-invariant", "03-bug-mutable-allow", "04-bug-budget-toctou", "05-bug-post-broadcast", "06-bug-fifo", "07-cta"].map(
    (s) => ({ id: `c01-${s}`, out: `carousels/C01-four-bugs/${s}.png`, w: 1080, h: 1350 }),
  ),
  ...["01-cover", "02-boundary-x402", "03-boundary-signgate", "04-boundary-cdp", "05-diagram-architecture", "06-cta"].map(
    (s) => ({ id: `c02-${s}`, out: `carousels/C02-three-boundaries/${s}.png`, w: 1080, h: 1350 }),
  ),
  ...["01-cover", "02-pipeline", "03-policy-vs-safety", "04-cdp-vs-hook", "05-cta"].map(
    (s) => ({ id: `c03-${s}`, out: `carousels/C03-invariant-pipeline/${s}.png`, w: 1080, h: 1350 }),
  ),
  ...["01-cover", "02-flow", "03-replay", "04-windows", "05-proof-terminal", "06-cta"].map(
    (s) => ({ id: `c04-${s}`, out: `carousels/C04-authorize-payment/${s}.png`, w: 1080, h: 1350 }),
  ),
  ...["01-cover", "02-state-machine", "03-rule", "04-ambiguous", "05-proof-terminal", "06-cta"].map(
    (s) => ({ id: `c05-${s}`, out: `carousels/C05-post-broadcast/${s}.png`, w: 1080, h: 1350 }),
  ),
  ...["01-cover", "02-fifo-vs-digest", "03-on-chain", "04-proof-terminal", "05-cta"].map(
    (s) => ({ id: `c06-${s}`, out: `carousels/C06-execution-digest/${s}.png`, w: 1080, h: 1350 }),
  ),
  ...["01-cover", "02-table-a", "03-table-b", "04-table-c", "05-rule", "06-cta"].map(
    (s) => ({ id: `c07-${s}`, out: `carousels/C07-source-of-truth/${s}.png`, w: 1080, h: 1350 }),
  ),
  ...["01-cover", "02-open-gaps", "03-not-in-v01", "04-proof-terminal", "05-cta"].map(
    (s) => ({ id: `c08-${s}`, out: `carousels/C08-honest-gaps/${s}.png`, w: 1080, h: 1350 }),
  ),
];

const html = await readFile(slidesHtml, "utf8");
const styleMatch = html.match(/<style>([\s\S]*?)<\/style>/);
const style = styleMatch?.[1] ?? "";
await mkdir(slidesDir, { recursive: true });

function extractSlide(id: string): string | null {
  const needle = `id="${id}"`;
  const idx = html.indexOf(needle);
  if (idx < 0) return null;
  const start = html.lastIndexOf("<div", idx);
  if (start < 0) return null;

  let depth = 0;
  let i = start;
  while (i < html.length) {
    const open = html.indexOf("<div", i);
    const close = html.indexOf("</div>", i);
    if (open !== -1 && open <= close) {
      depth++;
      i = open + 4;
      continue;
    }
    if (close !== -1) {
      depth--;
      i = close + 6;
      if (depth === 0) return html.slice(start, i);
      continue;
    }
    break;
  }
  return null;
}

async function screenshotSlide(slide: Slide) {
  const fragment = extractSlide(slide.id);
  if (!fragment) {
    console.warn(`skip missing #${slide.id}`);
    return false;
  }

  const single = `<!DOCTYPE html><html><head><meta charset="UTF-8"><style>
${style}
html,body{margin:0;padding:0;width:${slide.w}px;height:${slide.h}px;overflow:hidden;background:#0A0B0D}
body{display:block}
.slide{margin:0!important}
</style></head><body>${fragment}</body></html>`;

  const tmpHtml = join(slidesDir, `${slide.id}.html`);
  const tmpPng = join(slidesDir, `${slide.id}.png`);
  await writeFile(tmpHtml, single);

  const proc = Bun.spawn(
    [
      chrome,
      "--headless=new",
      "--disable-gpu",
      "--hide-scrollbars",
      `--window-size=${slide.w},${slide.h}`,
      `--screenshot=${tmpPng}`,
      `file:///${tmpHtml.replace(/\\/g, "/")}`,
    ],
    { stdout: "pipe", stderr: "pipe" },
  );
  const code = await proc.exited;
  if (code !== 0 || !existsSync(tmpPng)) {
    const err = await new Response(proc.stderr).text();
    console.warn(`chrome failed #${slide.id}: ${err}`);
    return false;
  }

  const outPath = join(root, slide.out);
  await mkdir(dirname(outPath), { recursive: true });
  await Bun.write(outPath, await Bun.file(tmpPng).arrayBuffer());
  console.log(`✓ ${slide.out}`);
  return true;
}

let ok = 0;
for (const slide of slides) {
  if (await screenshotSlide(slide)) ok++;
}

console.log(`\nGenerated ${ok}/${slides.length} PNGs → ${root}`);
console.log(`Browser: ${chrome}`);
