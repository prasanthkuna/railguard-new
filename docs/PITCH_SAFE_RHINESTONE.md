# Pitch — Safe / Rhinestone / account abstraction

**Audience:** Smart account modules, session keys, execution hooks

## One paragraph

Railguard demonstrates session-scoped execution safety for agent payments: ERC-4337-style nonce lanes, dual EIP-712 registration (owner + Railguard), an execution hook that enforces token/recipient/caps on single and batch USDC transfers, and `executionDigest` reconciliation so off-chain ledger matches on-chain events by identity — not FIFO. v0.1 is an adapter + hook prototype, not a claim of generic ERC-7579 compatibility.

## Technical hooks

- `RailguardAccountAdapter` — account-local session storage
- `RailguardExecutionHook` — preCheck / postCheck, spend commit
- `RailguardSessionValidator` — session key + nonce lane
- Foundry `PrdDemo` — allow + three attack blocks

## Proof (5 min)

```powershell
cd railguard-new\contracts
forge test --match-contract PrdDemo -vv
```

## Link

[PORTFOLIO.md](./PORTFOLIO.md) · [INTERVIEW_PREP.md](./INTERVIEW_PREP.md)
