# Receipt Schema (v1)

```json
{
  "receiptVersion": "railguard.v1",
  "decisionId": "dec_...",
  "decision": "ALLOW",
  "reasonCodes": ["WITHIN_LIMITS"],
  "agentId": "agent_...",
  "intentHash": "0x...",
  "policyHash": "0x...",
  "sessionId": "0x...",
  "nonceKey": "12345",
  "chainId": 84532,
  "token": "0x...",
  "recipient": "0x...",
  "amountAtomic": "100000000",
  "allowBatch": false,
  "validUntil": 1760003600,
  "signerKeyId": "railguard-key-v1",
  "createdAt": "2026-07-08T00:00:00Z",
  "signature": "0x..."
}
```

Signed with secp256k1 over SHA-256 of canonical JSON payload.
