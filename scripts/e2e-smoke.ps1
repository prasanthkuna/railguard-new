# Smoke E2E: SignGate health + intent evaluate only (no deploy, no on-chain execution).
# Use scripts/e2e-happy-path.ps1 for the canonical PRD E2E.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "==> SignGate smoke (API only)"
powershell -File "$root\scripts\smoke-signgate.ps1"
Write-Host "Smoke E2E passed."
