$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$EvidenceRoot = Join-Path $Root "evidence"
New-Item -ItemType Directory -Force -Path $EvidenceRoot | Out-Null

$forge = "$env:USERPROFILE\.foundry\bin\forge.exe"
if (-not (Test-Path $forge)) { $forge = "forge" }

Write-Host "==> Stellar testnet (live Horizon payout)"
Push-Location (Join-Path $Root "..\stellar-payment-assurance-kit")
try {
  npm install --no-fund --no-audit 2>&1 | Out-Null
  npm run testnet-evidence | Tee-Object -FilePath (Join-Path $EvidenceRoot "stellar-testnet.json")
  if ($LASTEXITCODE -ne 0) { throw "Stellar testnet evidence failed" }
} finally { Pop-Location }

Write-Host "==> Base Sepolia (live RPC settlement verification)"
Push-Location (Join-Path $Root "..\coinbase")
try {
  bun run testnet-evidence | Tee-Object -FilePath (Join-Path $EvidenceRoot "base-sepolia-testnet.json")
  if ($LASTEXITCODE -ne 0) { throw "Base Sepolia testnet evidence failed" }
} finally { Pop-Location }

Write-Host "==> railguard-new on-chain (APF-006 forge)"
Push-Location (Join-Path $Root "contracts")
try {
  & $forge test --match-contract PrdDemo -vv
  if ($LASTEXITCODE -ne 0) { throw "forge PrdDemo tests failed" }
} finally { Pop-Location }

$manifest = @{
  generatedAt = (Get-Date).ToUniversalTime().ToString("o")
  networks    = @("stellar-testnet", "base-sepolia", "anvil-forge")
  evidenceDir = $EvidenceRoot
  ok          = $true
} | ConvertTo-Json -Depth 4

$manifest | Set-Content (Join-Path $EvidenceRoot "testnet-manifest.json")
Write-Host $manifest
Write-Host "Testnet evidence complete. Artifacts in $EvidenceRoot"
