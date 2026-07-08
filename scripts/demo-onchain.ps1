# PRD on-chain demo: one allowed transfer + three blocked attacks.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$forge = "$env:USERPROFILE\.foundry\bin\forge.exe"
if (-not (Test-Path $forge)) { $forge = "forge" }

Write-Host "==> Railguard PRD on-chain demo (Foundry)"
Push-Location "$root\contracts"
& $forge test --match-contract PrdDemoTest -vv
if ($LASTEXITCODE -ne 0) { throw "PRD demo tests failed" }
Pop-Location
Write-Host "PRD on-chain demo passed."
