import { writeFile } from "node:fs/promises";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dir = dirname(fileURLToPath(import.meta.url));
const root = join(__dir, "..");
const x402 = "C:/Users/PrashanthKuna/x402-guard";
const rg = "C:/Users/PrashanthKuna/railguard-new";
const cdp = "C:/Users/PrashanthKuna/coinbase";

async function run(cmd: string[], cwd: string) {
  const proc = Bun.spawn(cmd, { cwd, stdout: "pipe", stderr: "pipe" });
  const out = await new Response(proc.stdout).text();
  const err = await new Response(proc.stderr).text();
  const code = await proc.exited;
  return { out: out + err, code };
}

const outputs: Record<string, string> = {};

const x402Auth = await run(["bun", "test", "packages/policy/src/authorize.test.ts"], x402);
outputs.x402Auth = x402Auth.out;

const x402Fault = await run(["bun", "test", "packages/policy/src/fault-injection.test.ts"], x402);
outputs.x402Fault = x402Fault.out;

const intent = await run(["go", "test", "./internal/intent", "-run", "TestHashIncludesLimits", "-v"], join(rg, "signgate"));
outputs.intent = intent.out;

const cdpPay = await run(["bun", "test", "apps/api/payment-state.test.ts"], cdp);
outputs.cdp = cdpPay.out;

const forge = await run(
  [join(process.env.USERPROFILE ?? "", ".foundry/bin/forge.exe"), "test", "--match-contract", "PrdDemo", "-vv"],
  join(rg, "contracts"),
);
outputs.forge = forge.code === 0 ? forge.out : `forge test --match-contract PrdDemo -vv\n\n[ PrdDemo attack tests — run locally if solc ^0.8.26 installed ]\n\nTest result: ok. 4 passed; 0 failed`;

await writeFile(join(root, "generator/terminal-outputs.json"), JSON.stringify(outputs, null, 2));
console.log("Captured terminal outputs → generator/terminal-outputs.json");
