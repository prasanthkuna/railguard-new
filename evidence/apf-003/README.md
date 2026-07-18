# APF-003 — Crash after broadcast

## Invariant

> A broadcast payment must retain its guard reservation until settlement is known.

**INV-001:** A broadcast transaction cannot release its reservation until settlement is definitively reverted.

## Vulnerable vs fixed

| Step | Vulnerable CDP | Fixed CDP |
|------|----------------|-----------|
| Broadcast | `submitted` | `submitted` |
| Post-broadcast crash | `unknown` + **released** (bug) | `unknown` + **frozen** |
| Retry | Allowed (overspend risk) | Blocked |
| Reconciler confirms | N/A | `confirmed` + **committed** |

## Proof layers

1. **Failure lab fixture** — `agent-payment-failure-lab` vulnerable-cdp vs fixed-cdp
2. **CDP unit tests** — `coinbase/apps/api/payment-lifecycle.test.ts`
3. **State machine tests** — `coinbase/apps/api/payment-state.test.ts`

## Reproduce

```bash
# Failure lab
cd agent-payment-failure-lab
npm run lab -- --profiles APF-003

# CDP implementation
cd coinbase
bun test apps/api/payment-lifecycle.test.ts apps/api/payment-state.test.ts
```

## Postmortem

[POSTMORTEM-APF-003](https://github.com/prasanthkuna/agent-payment-failure-lab/blob/main/docs/POSTMORTEM-APF-003.md)
