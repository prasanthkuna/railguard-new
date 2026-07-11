# Apply idempotent SQL migrations to the docker-compose Postgres service.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$composeFile = Join-Path $root "docker-compose.yml"

$pg = docker compose -f $composeFile ps -q postgres
if (-not $pg) {
  throw "postgres container not running - start with: docker compose up -d postgres"
}

$migrations = @(
  "001_init.sql",
  "002_watcher.sql",
  "002_policy_decision_consumption.sql",
  "003_intent_limits_and_session_binding.sql",
  "004_execution_digest.sql"
)

foreach ($file in $migrations) {
  $path = Join-Path $root "db\migrations\$file"
  if (-not (Test-Path $path)) { throw "missing migration: $path" }
  Write-Host "==> applying $file"
  Get-Content $path -Raw | docker exec -i $pg psql -U railguard -d railguard -v ON_ERROR_STOP=1 -f - | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "migration failed: $file" }
}

Write-Host "Database migrations applied."
