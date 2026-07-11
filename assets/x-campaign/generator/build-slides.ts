import { readFile, writeFile } from "node:fs/promises";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dir = dirname(fileURLToPath(import.meta.url));

function esc(s: string) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

const terminals = JSON.parse(
  await readFile(join(__dir, "terminal-outputs.json"), "utf8").catch(() => "{}"),
) as Record<string, string>;

const term = (key: string, fallback: string) =>
  `<pre class="terminal">${esc(terminals[key] ?? fallback)}</pre>`;

const CSS = `
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --bg:#0A0B0D;--elevated:#14161A;--border:#2A2D35;
  --text:#F4F4F5;--muted:#A1A1AA;
  --blue:#3B82F6;--purple:#A78BFA;--cyan:#22D3EE;
  --green:#22C55E;--red:#EF4444;--amber:#F59E0B;
}
body{background:#111;padding:24px;font-family:Inter,system-ui,sans-serif}
.slide{position:relative;overflow:hidden;background:var(--bg);color:var(--text);font-family:Inter,system-ui,sans-serif}
.slide::before{content:'';position:absolute;inset:0;background:linear-gradient(135deg,transparent 60%,rgba(59,130,246,.06));pointer-events:none}
.chrome{position:absolute;top:40px;left:48px;right:48px;display:flex;justify-content:space-between;align-items:center;z-index:2}
.logo{font-weight:700;font-size:18px;color:var(--blue);letter-spacing:-.02em}
.logo span{color:var(--muted);font-weight:500;font-size:14px;margin-left:8px}
.counter{font-family:'JetBrains Mono',monospace;font-size:14px;color:var(--muted)}
.footer{position:absolute;bottom:40px;left:48px;right:48px;font-size:13px;color:var(--muted);display:flex;justify-content:space-between;z-index:2}
.pad{padding:120px 64px 88px;height:100%;display:flex;flex-direction:column;justify-content:center}
.eyebrow{font-size:13px;font-weight:600;letter-spacing:.12em;text-transform:uppercase;color:var(--blue);margin-bottom:16px}
h1{font-size:52px;font-weight:700;line-height:1.1;letter-spacing:-.03em;margin-bottom:16px}
h2{font-size:40px;font-weight:700;line-height:1.15;margin-bottom:20px}
.sub{font-size:22px;color:var(--muted);line-height:1.4;max-width:90%}
.pipeline{font-family:'JetBrains Mono',monospace;font-size:22px;line-height:1.6;color:var(--text);text-align:center;padding:24px;background:var(--elevated);border:1px solid var(--border);border-radius:12px}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin:20px 0}
.card{background:var(--elevated);border:1px solid var(--border);border-radius:12px;padding:20px}
.card h3{font-size:18px;margin-bottom:8px}
.card p{font-size:15px;color:var(--muted);line-height:1.35}
.card.red{border-color:var(--red)}.card.red h3{color:var(--red)}
.card.green{border-color:var(--green)}.card.green h3{color:var(--green)}
.card.blue{border-top:4px solid var(--blue)}.card.purple{border-top:4px solid var(--purple)}.card.cyan{border-top:4px solid var(--cyan)}
.exploit-fix{display:grid;grid-template-columns:1fr 40px 1fr;gap:12px;align-items:stretch;margin:16px 0}
.col{padding:20px;border-radius:12px;background:var(--elevated);border:1px solid var(--border)}
.col.before{border-color:var(--red)}.col.after{border-color:var(--green)}
.col h3{font-size:16px;margin-bottom:10px}.col.before h3{color:var(--red)}.col.after h3{color:var(--green)}
.col p{font-size:14px;color:var(--muted);line-height:1.4}
.arrow{display:flex;align-items:center;justify-content:center;font-size:28px;color:var(--muted)}
.quote{margin-top:auto;padding:16px 20px;border-left:4px solid var(--blue);font-style:italic;font-size:17px;color:var(--text);background:var(--elevated);border-radius:0 8px 8px 0}
.flow{display:flex;flex-direction:column;gap:12px}
.step{display:flex;align-items:center;gap:16px;padding:16px;background:var(--elevated);border:1px solid var(--border);border-radius:10px}
.step .n{font-family:'JetBrains Mono',monospace;width:36px;height:36px;border-radius:50%;background:var(--blue);color:var(--bg);display:flex;align-items:center;justify-content:center;font-weight:600;font-size:14px;flex-shrink:0}
.step code{font-family:'JetBrains Mono',monospace;font-size:15px}
.diagram{display:flex;align-items:center;justify-content:center;gap:8px;flex-wrap:wrap;padding:20px 0}
.dbox{padding:16px 14px;background:var(--elevated);border:2px solid var(--border);border-radius:10px;text-align:center;min-width:100px}
.dbox small{display:block;font-size:11px;color:var(--muted);margin-top:6px}
.dbox.blue{border-color:var(--blue)}.dbox.purple{border-color:var(--purple)}.dbox.cyan{border-color:var(--cyan)}
.darr{color:var(--muted);font-size:20px}
.table{width:100%;border-collapse:collapse;font-size:16px}
.table th,.table td{border:1px solid var(--border);padding:14px 16px;text-align:left}
.table th{background:var(--elevated);color:var(--muted);font-weight:600;font-size:13px;text-transform:uppercase;letter-spacing:.06em}
.table td code{font-family:'JetBrains Mono',monospace;font-size:13px;color:var(--cyan)}
.pills{display:flex;gap:10px;flex-wrap:wrap;margin-top:16px}
.pill{padding:8px 14px;border:1px solid var(--border);border-radius:999px;font-size:13px;color:var(--muted)}
.cta-url{font-family:'JetBrains Mono',monospace;font-size:14px;color:var(--blue);margin-top:12px;word-break:break-all}
.terminal{font-family:'JetBrains Mono',monospace;font-size:11px;line-height:1.45;background:#0d0d0d;border:1px solid var(--border);border-radius:10px;padding:16px;color:#d4d4d4;white-space:pre-wrap;max-height:520px;overflow:hidden}
.bullets{list-style:none;font-size:20px;line-height:1.7;color:var(--muted)}
.bullets li::before{content:'·';color:var(--blue);margin-right:10px;font-weight:700}
.mark-wrap{display:flex;align-items:center;justify-content:center;height:100%}
.mark{width:200px;height:200px;position:relative}
.mark::before{content:'';position:absolute;left:50%;top:20px;bottom:20px;width:6px;background:var(--blue);transform:translateX(-50%);border-radius:3px}
.mark::after{content:'';position:absolute;left:20px;right:20px;top:50%;height:6px;background:var(--blue);transform:translateY(-50%);border-radius:3px}
.mark-shield{position:absolute;right:30px;top:30px;width:70px;height:80px;border:3px solid var(--blue);border-radius:8px 8px 40% 40%}
.wide-grid{display:grid;grid-template-columns:1.1fr 1fr;gap:32px;align-items:center;height:100%}
`;

function slide(id: string, w: number, h: number, counter: string, body: string) {
  return `<div class="slide" id="${id}" style="width:${w}px;height:${h}px">
  <div class="chrome"><div class="logo">Railguard <span>v0.1-reference</span></div>${counter ? `<div class="counter">${counter}</div>` : ""}</div>
  ${body}
  <div class="footer"><span>reference implementation · not mainnet production</span><span>@prasanth_kuna</span></div>
</div>`;
}

function carousel(id: string, n: number, total: number, body: string) {
  return slide(id, 1080, 1350, `${String(n).padStart(2, "0")} / ${String(total).padStart(2, "0")}`, `<div class="pad">${body}</div>`);
}

const PORTFOLIO = "github.com/prasanthkuna/railguard-new/blob/master/docs/PORTFOLIO.md";

const ctaBody = `
<h2>Review the state machine</h2>
<p class="sub">v0.1-reference across three repos. E2E proof. Honest gaps documented.</p>
<div class="cta-url">${PORTFOLIO}</div>
<div class="pills"><span class="pill">x402-guard</span><span class="pill">railguard-new</span><span class="pill">railguard-cdp</span></div>
<p class="sub" style="margin-top:20px">If you review money-moving systems — poke holes in the state machine.</p>`;

const parts: string[] = [];

// Brand
parts.push(slide("brand-logo-mark", 512, 512, "", `<div class="mark-wrap"><div class="mark"><div class="mark-shield"></div></div></div>`));
parts.push(slide("brand-wordmark", 1200, 400, "", `<div class="pad" style="flex-direction:row;align-items:center;gap:32px;padding:80px"><div class="mark" style="transform:scale(.7)"><div class="mark-shield"></div></div><div><div style="font-size:56px;font-weight:700">Railguard</div><div style="font-family:JetBrains Mono;color:var(--muted);margin-top:8px">v0.1-reference</div></div></div>`));

// Pin / hero
const pinBody = `
<div class="wide-grid pad">
<div>
<div class="eyebrow">Security audit · v0.1</div>
<h1 style="font-size:44px">Agent payments fail on glue, not validators</h1>
<p class="sub">Atomicity and truth convergence across x402, hook, and CDP.</p>
<div class="cta-url" style="margin-top:24px">${PORTFOLIO}</div>
</div>
<div>
<div class="grid2">
<div class="card red"><h3>Mutable ALLOW</h3><p>limits outside intent hash</p></div>
<div class="card red"><h3>Budget TOCTOU</h3><p>read → pay → record</p></div>
<div class="card red"><h3>Post-broadcast lie</h3><p>failed after tx hash</p></div>
<div class="card red"><h3>FIFO reconcile</h3><p>oldest reservation wins</p></div>
</div>
<div class="pipeline" style="margin-top:16px;font-size:16px">Intent → Policy → Session → Signature → Hook → Receipt → Reconcile</div>
</div></div>`;
parts.push(slide("pin-one-pager", 1600, 900, "", pinBody));
parts.push(slide("pin-hero", 1600, 900, "", pinBody));

parts.push(slide("profile-banner", 1500, 500, "", `<div class="pad" style="text-align:center"><h1 style="font-size:42px">Railguard · v0.1-reference</h1><p class="sub" style="margin:12px auto 0">x402 policy · on-chain hook · CDP reconciliation</p></div>`));
parts.push(slide("og-image", 1200, 630, "", `<div class="pad"><h1>Railguard v0.1-reference</h1><p class="sub">4 bugs fixed · E2E proof · honest gaps</p></div>`));

parts.push(slide("diagram-boundaries", 1200, 1200, "", `<div class="pad">
<h2 style="text-align:center">Three enforcement boundaries</h2>
<div class="diagram" style="margin-top:40px">
<span class="dbox" style="min-width:70px"><div>Agent</div></span><span class="darr">→</span>
<span class="dbox blue"><div>x402-guard</div><small>Pre-sign</small></span><span class="darr">→</span>
<span class="dbox purple"><div>SignGate + Hook</div><small>Execute</small></span><span class="darr">→</span>
<span class="dbox cyan"><div>CDP + Reconciler</div><small>Reconcile</small></span><span class="darr">→</span>
<span class="dbox"><div>Chain</div></span>
</div>
<p class="sub" style="text-align:center;margin-top:32px">Miss one boundary → money moves without truth.</p>
</div>`));

// Terminals
parts.push(slide("proof-x402", 1600, 900, "", `<div class="pad"><h2>x402 authorizePayment</h2>${term("x402Auth", "bun test authorize.test.ts\n(pass) 1 pass 0 fail")}</div>`));
parts.push(slide("proof-forge", 1600, 900, "", `<div class="pad"><h2>Forge PrdDemo — attacks blocked</h2>${term("forge", "forge test --match-contract PrdDemo -vv")}</div>`));
parts.push(carousel("proof-cdp", 1, 1, `<h2>CDP payment state</h2>${term("cdp", "bun test payment-state.test.ts")}`));
parts.push(carousel("proof-intent", 1, 1, `<h2>Intent hash includes limits</h2>${term("intent", "go test TestHashIncludesLimits -v")}`));

// Minimal carousel
parts.push(carousel("min-01", 1, 5, `<div class="eyebrow">Thesis</div><h1>Atomicity + truth convergence</h1><p class="sub">3-repo agent payment stack · v0.1-reference</p><div class="pipeline" style="margin-top:32px">Intent → Policy → Session → Signature → Hook → Receipt → Reconcile</div>`));
parts.push(carousel("min-02", 2, 5, `<h2>4 bugs</h2><ul class="bullets" style="margin-top:24px"><li>Mutable ALLOW — limits outside intent hash</li><li>Budget TOCTOU — read then pay then record</li><li>Post-broadcast lie — failed after tx hash</li><li>FIFO reconcile — oldest reservation wins</li></ul>`));
parts.push(carousel("min-03", 3, 5, `<h2>4 fixes</h2><ul class="bullets" style="margin-top:24px"><li>Canonical intent hash + immutable persist</li><li>authorizePayment reserve / commit</li><li>unknown + reconciler after broadcast</li><li>executionDigest identity match</li></ul>`));
parts.push(carousel("min-04", 4, 5, `<h2>Three boundaries</h2><div class="diagram" style="margin-top:24px"><span class="dbox blue"><div>x402-guard</div><small>Pre-sign</small></span><span class="darr">→</span><span class="dbox purple"><div>Hook</div><small>Execute</small></span><span class="darr">→</span><span class="dbox cyan"><div>CDP</div><small>Reconcile</small></span></div>`));
parts.push(carousel("min-05", 5, 5, ctaBody));

// C01
parts.push(carousel("c01-01-cover", 1, 7, `<div class="eyebrow">Security audit · v0.1</div><h1>4 bugs in agent payment stacks</h1><p class="sub">Atomicity and truth convergence — not missing validators</p>`));
parts.push(carousel("c01-02-invariant", 2, 7, `<h2>The invariant</h2><div class="pipeline" style="margin-top:32px;font-size:20px">Intent → Policy → Session → Signature → Hook → Receipt → Reconcile</div>`));
for (const [id, n, title, before, after, quote] of [
  ["c01-03-bug-mutable-allow", 3, "Bug 1 — Mutable ALLOW", "limits excluded from intent hash", "canonical hash + immutable persist", "Authorization only matters if approved facts cannot change."],
  ["c01-04-bug-budget-toctou", 4, "Bug 2 — Budget TOCTOU", "read → pay → record", "authorizePayment reserve/commit", "Budget enforcement is a reservation, not a read."],
  ["c01-05-bug-post-broadcast", 5, "Bug 3 — Post-broadcast lie", "DB fails → status failed", "unknown + reconciler", "Exception text is not financial truth."],
  ["c01-06-bug-fifo", 6, "Bug 4 — FIFO reconcile", "oldest reservation", "executionDigest match", "Reconcile by identity, not queue position."],
] as const) {
  parts.push(carousel(id, n, 7, `<h2>${title}</h2><div class="exploit-fix"><div class="col before"><h3>Before</h3><p>${before}</p></div><div class="arrow">→</div><div class="col after"><h3>After</h3><p>${after}</p></div></div><div class="quote">${quote}</div>`));
}
parts.push(carousel("c01-07-cta", 7, 7, ctaBody));

// C02
parts.push(carousel("c02-01-cover", 1, 6, `<h1>Three repos · Three enforcement boundaries</h1>`));
parts.push(carousel("c02-02-boundary-x402", 2, 6, `<div class="card blue" style="padding:32px"><h2 style="color:var(--blue)">Boundary 1 — x402-guard</h2><p class="sub" style="margin-top:12px;color:var(--text)">Pre-sign policy · authorizePayment</p></div>`));
parts.push(carousel("c02-03-boundary-signgate", 3, 6, `<div class="card purple" style="padding:32px"><h2 style="color:var(--purple)">Boundary 2 — railguard-new</h2><p class="sub" style="margin-top:12px;color:var(--text)">SignGate + on-chain hook · session caps</p></div>`));
parts.push(carousel("c02-04-boundary-cdp", 4, 6, `<div class="card cyan" style="padding:32px"><h2 style="color:var(--cyan)">Boundary 3 — railguard-cdp</h2><p class="sub" style="margin-top:12px;color:var(--text)">Invoice + CDP broadcast + reconciler</p></div>`));
parts.push(carousel("c02-05-diagram-architecture", 5, 6, `<div class="diagram"><span class="dbox blue"><div>x402-guard</div></span><span class="darr">→</span><span class="dbox purple"><div>SignGate+Hook</div></span><span class="darr">→</span><span class="dbox cyan"><div>CDP</div></span><span class="darr">→</span><span class="dbox"><div>Chain</div></span></div>`));
parts.push(carousel("c02-06-cta", 6, 6, ctaBody));

// C03
parts.push(carousel("c03-01-cover", 1, 5, `<h1>One payment, seven checkpoints</h1>`));
parts.push(carousel("c03-02-pipeline", 2, 5, `<div class="pipeline" style="font-size:18px">Intent → Policy → Session → Signature → Hook → Receipt → Reconcile</div>`));
parts.push(carousel("c03-03-policy-vs-safety", 3, 5, `<h2>Policy intelligence ≠ asset safety</h2><ul class="bullets" style="margin-top:24px"><li>OPA decides</li><li>Hook enforces</li><li>Reconciler converges</li></ul>`));
parts.push(carousel("c03-04-cdp-vs-hook", 4, 5, `<h2>CDP vs hook</h2><p class="sub" style="margin-top:16px">CDP = invoice workflow + broadcast truth</p><p class="sub" style="margin-top:12px">Hook = smart-account physical ceiling</p>`));
parts.push(carousel("c03-05-cta", 5, 5, ctaBody));

// C04
parts.push(carousel("c04-01-cover", 1, 6, `<h1>x402 budget enforcement</h1><p class="sub">One primitive, four steps</p>`));
parts.push(carousel("c04-02-flow", 2, 6, `<div class="flow"><div class="step"><span class="n">1</span><code>claimReplay(fingerprint)</code></div><div class="step"><span class="n">2</span><code>reserveBudget(agent, amount, windows)</code></div><div class="step"><span class="n">3</span><code>callback / sign / pay</code></div><div class="step"><span class="n">4</span><code>commitAuthorization OR releaseAuthorization</code></div></div>`));
parts.push(carousel("c04-03-replay", 3, 6, `<h2>Replay</h2><p class="sub" style="margin-top:16px">claimReplay is atomic — not hasReplay then markReplay</p>`));
parts.push(carousel("c04-04-windows", 4, 6, `<h2>Windows</h2><p class="sub" style="margin-top:16px">Rolling limits · reserve before callback · commit or release</p>`));
parts.push(carousel("c04-05-proof-terminal", 5, 6, term("x402Auth", "bun test authorize.test.ts")));
parts.push(carousel("c04-06-cta", 6, 6, ctaBody));

// C05
parts.push(carousel("c05-01-cover", 1, 6, `<h1>After CDP returns a tx hash</h1><p class="sub">Exception text is not financial truth</p>`));
parts.push(carousel("c05-02-state-machine", 2, 6, `<div class="pipeline" style="font-size:16px">draft → approved → submitted → <span style="color:var(--amber)">unknown?</span> → confirmed</div><p class="sub" style="margin-top:20px">Never failed after broadcastedTxHash exists</p>`));
parts.push(carousel("c05-03-rule", 3, 6, `<h2>Rule</h2><p class="sub" style="margin-top:16px">If broadcastedTxHash exists → never mark failed on DB error</p>`));
parts.push(carousel("c05-04-ambiguous", 4, 6, `<h2>Ambiguous states</h2><p class="sub" style="margin-top:16px">submitted / unknown until reconciler + receipt</p>`));
parts.push(carousel("c05-05-proof-terminal", 5, 6, term("cdp", "bun test payment-state.test.ts")));
parts.push(carousel("c05-06-cta", 6, 6, ctaBody));

// C06
parts.push(carousel("c06-01-cover", 1, 5, `<h1>Reconcile by identity</h1><p class="sub">Not FIFO</p>`));
parts.push(carousel("c06-02-fifo-vs-digest", 2, 5, `<div class="exploit-fix"><div class="col before"><h3>FIFO wrong</h3><p>oldest reservation wins</p></div><div class="arrow">→</div><div class="col after"><h3>By digest</h3><p>match executionDigest to row</p></div></div>`));
parts.push(carousel("c06-03-on-chain", 3, 5, `<h2>On-chain</h2><code style="font-family:JetBrains Mono;font-size:16px;display:block;margin-top:20px">ExecutionAllowed(account, executionDigest, …)</code>`));
parts.push(carousel("c06-04-proof-terminal", 4, 5, term("forge", "forge test --match-contract PrdDemo -vv")));
parts.push(carousel("c06-05-cta", 5, 5, ctaBody));

// C07
parts.push(carousel("c07-01-cover", 1, 6, `<h1>Who owns financial truth?</h1>`));
parts.push(carousel("c07-02-table-a", 2, 6, `<table class="table"><tr><th>Question</th><th>Authority</th></tr><tr><td>x402 payment allowed?</td><td><code>authorizePayment</code></td></tr><tr><td>On-chain spend?</td><td>Hook + session</td></tr></table>`));
parts.push(carousel("c07-03-table-b", 3, 6, `<table class="table"><tr><th>Question</th><th>Authority</th></tr><tr><td>CDP broadcast?</td><td><code>broadcastedTxHash</code></td></tr><tr><td>Transfer succeeded?</td><td>receipt status</td></tr></table>`));
parts.push(carousel("c07-04-table-c", 4, 6, `<table class="table"><tr><th>Question</th><th>Authority</th></tr><tr><td>Audit trail?</td><td>hash-chained audit</td></tr><tr><td>Reservation ↔ execution?</td><td><code>executionDigest</code></td></tr></table>`));
parts.push(carousel("c07-05-rule", 5, 6, `<h2>Rule of thumb</h2><p class="sub" style="margin-top:16px">Terminal states converge to chain evidence</p>`));
parts.push(carousel("c07-06-cta", 6, 6, ctaBody));

// C08
parts.push(carousel("c08-01-cover", 1, 5, `<h1>v0.1 reference implementation</h1><p class="sub">What I did not ship</p>`));
parts.push(carousel("c08-02-open-gaps", 2, 5, `<h2>Still open</h2><ul class="bullets" style="margin-top:20px"><li>Deep reorg rewind</li><li>HSM/MPC cosigners</li><li>Postgres fault-injection at API boundary</li></ul>`));
parts.push(carousel("c08-03-not-in-v01", 3, 5, `<h2>Not in v0.1</h2><ul class="bullets" style="margin-top:20px"><li>Paymaster · Solana · multi-chain</li><li>Dashboard · mainnet funds</li></ul>`));
parts.push(carousel("c08-04-proof-terminal", 4, 5, `<h2>E2E proof</h2><p class="sub">docker compose + e2e-happy-path.ps1</p><div class="card green" style="margin-top:20px;padding:24px"><h3 style="color:var(--green)">PASS</h3><p>Full stack reconciliation</p></div>`));
parts.push(carousel("c08-05-cta", 5, 5, ctaBody));

const html = `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Railguard X Slides</title><style>${CSS}</style></head><body>${parts.join("\n")}</body></html>`;

await writeFile(join(__dir, "slides.html"), html);
console.log(`Built slides.html with ${parts.length} slides`);
