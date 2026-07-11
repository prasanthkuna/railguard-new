import { chromium } from "playwright";
import { mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { homedir } from "node:os";

const __dir = dirname(fileURLToPath(import.meta.url));
const root = join(__dir, "..");
const htmlPath = join(__dir, "slides.html");

type Slide = { id: string; out: string; w: number; h: number };

const slides: Slide[] = [
  // brand
  { id: "brand-logo-mark", out: "brand/logo-mark-512.png", w: 512, h: 512 },
  { id: "brand-wordmark", out: "brand/logo-wordmark-1200x400.png", w: 1200, h: 400 },
  // standalone
  { id: "pin-one-pager", out: "pin-one-pager.png", w: 1600, h: 900 },
  { id: "pin-hero", out: "standalone/pin-hero-1600x900.png", w: 1600, h: 900 },
  { id: "profile-banner", out: "standalone/profile-banner-1500x500.png", w: 1500, h: 500 },
  { id: "og-image", out: "standalone/og-1200x630.png", w: 1200, h: 630 },
  { id: "diagram-boundaries", out: "diagram-boundaries.png", w: 1200, h: 1200 },
  // terminal proofs
  { id: "proof-x402", out: "proof-x402.png", w: 1600, h: 900 },
  { id: "proof-forge", out: "proof-forge.png", w: 1600, h: 900 },
  { id: "proof-cdp", out: "screenshots/terminal-cdp-payment-state.png", w: 1080, h: 1350 },
  { id: "proof-intent", out: "screenshots/terminal-intent-hash.png", w: 1080, h: 1350 },
  // minimal carousel
  { id: "min-01", out: "carousels/minimal/01-thesis.png", w: 1080, h: 1350 },
  { id: "min-02", out: "carousels/minimal/02-bugs.png", w: 1080, h: 1350 },
  { id: "min-03", out: "carousels/minimal/03-fix.png", w: 1080, h: 1350 },
  { id: "min-04", out: "carousels/minimal/04-diagram.png", w: 1080, h: 1350 },
  { id: "min-05", out: "carousels/minimal/05-cta.png", w: 1080, h: 1350 },
  // C01
  ...["01-cover", "02-invariant", "03-bug-mutable-allow", "04-bug-budget-toctou", "05-bug-post-broadcast", "06-bug-fifo", "07-cta"].map(
    (s) => ({ id: `c01-${s}`, out: `carousels/C01-four-bugs/${s}.png`, w: 1080, h: 1350 }),
  ),
  // C02
  ...["01-cover", "02-boundary-x402", "03-boundary-signgate", "04-boundary-cdp", "05-diagram-architecture", "06-cta"].map(
    (s) => ({ id: `c02-${s}`, out: `carousels/C02-three-boundaries/${s}.png`, w: 1080, h: 1350 }),
  ),
  // C03
  ...["01-cover", "02-pipeline", "03-policy-vs-safety", "04-cdp-vs-hook", "05-cta"].map(
    (s) => ({ id: `c03-${s}`, out: `carousels/C03-invariant-pipeline/${s}.png`, w: 1080, h: 1350 }),
  ),
  // C04
  ...["01-cover", "02-flow", "03-replay", "04-windows", "05-proof-terminal", "06-cta"].map(
    (s) => ({ id: `c04-${s}`, out: `carousels/C04-authorize-payment/${s}.png`, w: 1080, h: 1350 }),
  ),
  // C05
  ...["01-cover", "02-state-machine", "03-rule", "04-ambiguous", "05-proof-terminal", "06-cta"].map(
    (s) => ({ id: `c05-${s}`, out: `carousels/C05-post-broadcast/${s}.png`, w: 1080, h: 1350 }),
  ),
  // C06
  ...["01-cover", "02-fifo-vs-digest", "03-on-chain", "04-proof-terminal", "05-cta"].map(
    (s) => ({ id: `c06-${s}`, out: `carousels/C06-execution-digest/${s}.png`, w: 1080, h: 1350 }),
  ),
  // C07
  ...["01-cover", "02-table-a", "03-table-b", "04-table-c", "05-rule", "06-cta"].map(
    (s) => ({ id: `c07-${s}`, out: `carousels/C07-source-of-truth/${s}.png`, w: 1080, h: 1350 }),
  ),
  // C08
  ...["01-cover", "02-open-gaps", "03-not-in-v01", "04-proof-terminal", "05-cta"].map(
    (s) => ({ id: `c08-${s}`, out: `carousels/C08-honest-gaps/${s}.png`, w: 1080, h: 1350 }),
  ),
];

async function launchBrowser() {
  const candidates = [
    "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
    "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
    join(homedir(), "AppData/Local/ms-playwright/chromium-1228/chrome-win64/chrome.exe"),
    join(homedir(), "AppData/Local/ms-playwright/chromium-1223/chrome-win64/chrome.exe"),
  ].filter((p) => existsSync(p));

  const base = {
    headless: true as const,
    timeout: 120_000,
    args: ["--disable-gpu", "--no-sandbox", "--disable-dev-shm-usage"],
  };

  let last: unknown;
  for (const executablePath of candidates) {
    try {
      console.log(`launching ${executablePath}`);
      return await chromium.launch({ ...base, executablePath });
    } catch (e) {
      last = e;
      console.warn(`failed: ${executablePath}`);
    }
  }
  throw last ?? new Error("No Chrome/Edge executable found");
}

async function main() {
  const browser = await launchBrowser();
  const page = await browser.newPage();
  await page.goto(`file:///${htmlPath.replace(/\\/g, "/")}`, { waitUntil: "load", timeout: 60_000 });
  await page.waitForTimeout(1500);

  let ok = 0;
  for (const slide of slides) {
    const el = page.locator(`#${slide.id}`);
    const count = await el.count();
    if (count === 0) {
      console.warn(`skip missing #${slide.id}`);
      continue;
    }
    const outPath = join(root, slide.out);
    await mkdir(dirname(outPath), { recursive: true });
    await el.screenshot({ path: outPath, type: "png" });
    console.log(`✓ ${slide.out}`);
    ok++;
  }

  await browser.close();
  console.log(`\nGenerated ${ok}/${slides.length} PNGs → ${root}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
