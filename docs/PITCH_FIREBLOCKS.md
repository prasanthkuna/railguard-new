# Pitch — Fireblocks / transaction policy

**Audience:** Institutional transaction policy, treasury, agent custody

## One paragraph

Railguard applies transaction-policy thinking to AI agent stablecoin payments: immutable approval facts (intent hash includes physical limits), atomic budget authorization (reserve/commit/release — not read-then-write), hash-chained audit, and post-broadcast state machines that never lie about whether money left the provider. v0.1 uses dev keys; production path documents HSM/MPC for SignGate cosigners.

## Mapping

| Fireblocks concept | Railguard v0.1 |
|--------------------|----------------|
| Policy engine | OPA + x402-guard |
| Transaction rules | Hook physical checks |
| Approval workflow | CDP invoice + `policy_snapshot_hash` |
| Audit trail | Hash-chained events + EIP-712 receipts |
| Idempotent execution | Exactly-once claim + execution idempotency keys |

## Proof

[FAILURE_MODES_FIXED.md](./FAILURE_MODES_FIXED.md)

## Link

[PORTFOLIO.md](./PORTFOLIO.md)
