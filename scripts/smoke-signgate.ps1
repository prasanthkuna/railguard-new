# Smoke test SignGate API (requires docker compose up)
$ErrorActionPreference = "Stop"
Start-Sleep -Seconds 2
$health = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method Get
Write-Host "Health:" ($health | ConvertTo-Json)

$body = @{
  agentId = "agent_support_bot_1"
  account = "0x0000000000000000000000000000000000000001"
  chainId = 84532
  token = "0x00000000000000000000000000000000000000aa"
  recipient = "0x0000000000000000000000000000000000000b01"
  amountAtomic = "100000000"
  limits = @{
    maxPerTransfer = "100000000"
    maxTotalSpend = "500000000"
  }
  resource = @{
    method = "POST"
    domain = "api.vendor.com"
    path = "/v1/report"
  }
  idempotencyKey = "idem_smoke_" + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
} | ConvertTo-Json -Depth 5

$eval = Invoke-RestMethod -Uri "http://localhost:8080/v1/intents/evaluate" -Method Post -Body $body -ContentType "application/json"
Write-Host "Evaluate:" ($eval | ConvertTo-Json -Depth 5)

if ($eval.decision -ne "ALLOW") { throw "expected ALLOW decision" }
Write-Host "Smoke test passed."
