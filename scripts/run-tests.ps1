# Run all Railguard tests (Windows)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$forge = "$env:USERPROFILE\.foundry\bin\forge.exe"

Write-Host "==> Foundry contracts"
Push-Location "$root\contracts"
& $forge test -vvv
Pop-Location

Write-Host "==> Go SignGate"
Push-Location "$root\signgate"
go test ./...
Pop-Location

Write-Host "==> TypeScript SDK"
Push-Location "$root\sdk"
npm test
Pop-Location

if (Get-Command opa -ErrorAction SilentlyContinue) {
  Write-Host "==> OPA policy"
  Push-Location $root
  opa test policy/
  Pop-Location
} elseif (Get-Command docker -ErrorAction SilentlyContinue) {
  Write-Host "==> OPA policy (Docker)"
  docker run --rm -v "${root}/policy:/policy" openpolicyagent/opa:latest test /policy
} else {
  Write-Host "==> OPA skipped (install opa or Docker; see scripts/run-opa-tests.ps1)"
}

Write-Host "All local tests completed."
