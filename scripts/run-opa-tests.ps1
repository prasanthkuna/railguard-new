# Run OPA policy tests (Windows). Uses local opa if installed, otherwise Docker.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Push-Location $root
try {
  if (Get-Command opa -ErrorAction SilentlyContinue) {
    Write-Host "==> OPA policy (local CLI)"
    opa test policy/
  } elseif (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "==> OPA policy (Docker openpolicyagent/opa)"
    docker run --rm -v "${root}/policy:/policy" openpolicyagent/opa:latest test /policy
  } else {
    Write-Error "Install OPA (https://www.openpolicyagent.org/docs/latest/#running-opa) or Docker to run policy tests."
  }
} finally {
  Pop-Location
}
