# Policy Model

## V1 decisions

`ALLOW` | `BLOCK` only

## Separation

- OPA may be **stricter** than on-chain hook
- On-chain hook must never be **looser** than physical safety floor

## Example rules (railguard.rego)

- Block sanctions hits
- Block wrong chain
- Block high-risk recipients
- Block unknown/blocked domains
- Allow known vendor under limits

## policyHash

Binds which off-chain policy bundle authorized a session. Not enforced by hook.
