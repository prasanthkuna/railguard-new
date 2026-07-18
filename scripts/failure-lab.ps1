$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

Write-Host "==> Agent Payment Failure Lab (APF-001..006)"
Push-Location (Join-Path $Root "..\agent-payment-failure-lab")
try {
  npm test
  npm run lab
} finally { Pop-Location }

Write-Host "==> x402-guard"
Push-Location (Join-Path $Root "..\x402-guard\packages\policy")
try { npx vitest run src/authorize.test.ts src/fault-injection.test.ts src/storage.test.ts } finally { Pop-Location }

Write-Host "==> railguard-cdp lifecycle"
Push-Location (Join-Path $Root "..\coinbase")
try {
  bun test apps/api/payment-state.test.ts apps/api/payment-lifecycle.test.ts apps/api/reconcile.test.ts apps/api/execution-claim.test.ts packages/settlement/src/index.test.ts
} finally { Pop-Location }

Write-Host "==> GNU Taler Merchant Reliability Lab (TMR-001..008)"
Push-Location (Join-Path $Root "..\gnu-taler-merchant-reliability-lab")
try { npm test } finally { Pop-Location }

Write-Host "==> Stellar Payment Assurance Kit (SPA-001..005)"
Push-Location (Join-Path $Root "..\stellar-payment-assurance-kit")
try { npm test } finally { Pop-Location }

$forge = "$env:USERPROFILE\.foundry\bin\forge.exe"
if (-not (Test-Path $forge)) { $forge = "forge" }

if (Test-Path $forge) {
  Write-Host "==> railguard-new on-chain (APF-006)"
  Push-Location (Join-Path $Root "contracts")
  try { & $forge test --match-contract PrdDemo -vv } finally { Pop-Location }
} elseif (Get-Command forge -ErrorAction SilentlyContinue) {
  Write-Host "==> railguard-new on-chain (APF-006)"
  Push-Location (Join-Path $Root "contracts")
  try { forge test --match-contract PrdDemo -vv } finally { Pop-Location }
} else {
  Write-Host "forge not in PATH; skip APF-006 on-chain (see agent-payment-failure-lab APF-006 simulation)"
}

if ($env:TESTNET_INTEGRATION -eq "1") {
  Write-Host "==> Live testnet evidence (Stellar + Base Sepolia)"
  powershell -NoProfile -File (Join-Path $PSScriptRoot "testnet-evidence.ps1")
  if ($LASTEXITCODE -ne 0) { throw "testnet evidence failed" }
}

Write-Host "Full product failure-lab checks passed."
