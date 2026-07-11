# Canonical PRD E2E: deploy → SignGate cosign → on-chain register/execute → watcher ingestion.
# Fails hard on any skipped step. Requires Docker + Foundry.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$forge = "$env:USERPROFILE\.foundry\bin\forge.exe"
if (-not (Test-Path $forge)) { $forge = "forge" }

$apiKey = if ($env:SIGNGATE_API_KEY) { $env:SIGNGATE_API_KEY } else { "dev-local-signgate-key" }
$headers = @{ "X-SignGate-API-Key" = $apiKey }
$rpc = if ($env:RPC_URL) { $env:RPC_URL } else { "http://localhost:8545" }

# Anvil account 2 (session key) and account 3 (recipient)
$SessionKey = "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
$Recipient = "0x90F79bf6EB2c4f870365E785982E1f101E93b906"
$NonceKey = "424242"
$ExecuteAmount = "50000000"

function Wait-HttpOk($uri, $timeoutSec = 60) {
  $deadline = (Get-Date).AddSeconds($timeoutSec)
  while ((Get-Date) -lt $deadline) {
    try {
      $r = Invoke-RestMethod -Uri $uri -Method Get
      if ($r.status -eq "ok") { return }
    } catch { }
    Start-Sleep -Seconds 2
  }
  throw "timeout waiting for $uri"
}

Write-Host "==> 1. Start infra (postgres, redis, anvil)"
Push-Location $root
docker compose up -d --force-recreate postgres redis anvil
Pop-Location

# Fresh Anvil chain — drop stale watcher cursor from prior runs.
$pg = docker compose -f (Join-Path $root "docker-compose.yml") ps -q postgres
if ($pg) {
  docker exec $pg psql -U railguard -d railguard -c "DELETE FROM watcher_state; DELETE FROM chain_executions;" 2>$null | Out-Null
}

$ready = $false
for ($i = 0; $i -lt 30; $i++) {
  try {
    $resp = Invoke-WebRequest -Uri $rpc -Method Post `
      -Body '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' `
      -ContentType "application/json" -UseBasicParsing
    if ($resp.StatusCode -eq 200 -and $resp.Content -match "result") {
      $ready = $true
      break
    }
  } catch { }
  Start-Sleep -Seconds 1
}
if (-not $ready) { throw "anvil not ready at $rpc" }

Write-Host "==> 2. Deploy contracts to Anvil"
powershell -File "$root\scripts\deploy-anvil.ps1"
$envFile = Join-Path $root ".env.local"
if (-not (Test-Path $envFile)) { throw "missing $envFile after deploy" }
Get-Content $envFile | ForEach-Object {
  if ($_ -match '^\s*([^#=]+)=(.*)$') {
    Set-Item -Path "env:$($Matches[1].Trim())" -Value $Matches[2].Trim()
  }
}

if (-not $env:ADAPTER_ADDRESS -or -not $env:HOOK_ADDRESS -or -not $env:USDC_ADDRESS) {
  throw "deploy-anvil did not set contract addresses"
}

Write-Host "==> 3. Restart SignGate with deployed adapter/hook"
Push-Location $root
$env:SIGNGATE_API_KEY = $apiKey
docker compose up -d --build --force-recreate signgate
Pop-Location
Wait-HttpOk "http://localhost:8080/health"

Write-Host "==> 4. Intent evaluate (real adapter + USDC)"
$evalBody = @{
  agentId = "agent_support_bot_1"
  account = $env:ADAPTER_ADDRESS
  chainId = 84532
  token = $env:USDC_ADDRESS
  recipient = $Recipient
  amountAtomic = $ExecuteAmount
  limits = @{ maxPerTransfer = "100000000"; maxTotalSpend = "500000000" }
  resource = @{ method = "POST"; domain = "api.vendor.com"; path = "/v1/report" }
  idempotencyKey = "idem_e2e_canon_1"
} | ConvertTo-Json -Depth 5
$eval = Invoke-RestMethod -Uri "http://localhost:8080/v1/intents/evaluate" -Method Post -Body $evalBody -ContentType "application/json"
if ($eval.decision -ne "ALLOW") { throw "expected ALLOW, got $($eval.decision)" }
Write-Host "decisionId=$($eval.decisionId) policyHash=$($eval.policyHash)"

Write-Host "==> 5. Session register (SignGate Railguard cosign)"
$regBody = @{
  decisionId = $eval.decisionId
  sessionKey = $SessionKey
  nonceKey = $NonceKey
  validAfter = 1
  validUntil = 9999999999
} | ConvertTo-Json -Depth 3
$reg = Invoke-RestMethod -Uri "http://localhost:8080/v1/sessions/register" -Method Post -Body $regBody -ContentType "application/json" -Headers $headers
if (-not $reg.sessionId -or -not $reg.railguardSignature) {
  throw "session register missing sessionId or railguardSignature"
}
Write-Host "sessionId=$($reg.sessionId)"

Write-Host "==> 6. Reserve budget"
$resBody = @{
  sessionId = $reg.sessionId
  agentId = "agent_support_bot_1"
  intentHash = $eval.intentHash
  amountAtomic = $ExecuteAmount
  idempotencyKey = "idem_reserve_e2e_1"
  maxTotalSpend = "500000000"
} | ConvertTo-Json -Depth 3
$res = Invoke-RestMethod -Uri "http://localhost:8080/v1/reservations/reserve" -Method Post -Body $resBody -ContentType "application/json" -Headers $headers
if ($res.status -ne "RESERVED") { throw "reservation failed: $($res | ConvertTo-Json)" }

Write-Host "==> 7. On-chain register + execute (same session)"
$AnvilOwnerKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
$env:OWNER_PRIVATE_KEY = $AnvilOwnerKey
$env:NONCE_KEY = $NonceKey
$env:SESSION_KEY = $SessionKey
$env:RECIPIENT = $Recipient
$env:EXECUTE_AMOUNT = $ExecuteAmount
$env:POLICY_HASH = $eval.policyHash
$env:VALID_AFTER = "1"
$env:VALID_UNTIL = "9999999999"
$env:RAILGUARD_SIGNATURE = $reg.railguardSignature
Push-Location "$root\contracts"
& $forge script script/E2eCanon.s.sol:E2eCanon --rpc-url $rpc --broadcast --private-key $AnvilOwnerKey 2>&1 | Write-Host
if ($LASTEXITCODE -ne 0) { throw "E2eCanon forge script failed" }
Pop-Location

# Mine one block so confirmation-depth watchers observe the execution block.
$mineBody = '{"jsonrpc":"2.0","method":"evm_mine","params":[],"id":1}'
Invoke-WebRequest -Uri $rpc -Method Post -Body $mineBody -ContentType "application/json" -UseBasicParsing | Out-Null

Write-Host "==> 8. Wait for watcher ExecutionAllowed ingestion"
$chainExec = $null
for ($i = 0; $i -lt 30; $i++) {
  try {
    $chainExec = Invoke-RestMethod -Uri "http://localhost:8080/v1/reconciliation/executions/$($reg.sessionId)" -Method Get -Headers $headers
    if ($chainExec.txHash) { break }
  } catch { }
  Start-Sleep -Seconds 2
}
if (-not $chainExec -or -not $chainExec.txHash) {
  throw "watcher did not ingest ExecutionAllowed for session $($reg.sessionId)"
}
Write-Host "watcher ingested txHash=$($chainExec.txHash) frameSpend=$($chainExec.frameSpend)"

Write-Host "==> 9. Receipt fetch (signed)"
$receipt = Invoke-RestMethod -Uri "http://localhost:8080/v1/receipts/$($eval.decisionId)" -Method Get -Headers $headers
if ($receipt.decision -ne "ALLOW" -or -not $receipt.receiptHash -or -not $receipt.signature) {
  throw "signed receipt missing or invalid"
}
Write-Host "receiptHash=$($receipt.receiptHash)"

Write-Host "Canonical PRD E2E passed."
