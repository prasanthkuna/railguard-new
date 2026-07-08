# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 0.1.x   | Yes       |

## Reporting a vulnerability

**Please do not open public GitHub issues for security vulnerabilities.**

Email **prasanthkuna@gmail.com** with:

- Description of the issue and impact
- Steps to reproduce (Foundry test, SignGate request, or E2E script)
- Affected component (`contracts/`, `signgate/`, `sdk/`, `policy/`)

I aim to acknowledge within 48 hours and provide a fix timeline for confirmed issues.

## Scope

In scope for this proof-of-work:

- On-chain hook bypass or session policy evasion
- SignGate auth bypass, reservation race, or receipt forgery
- Cross-language vector mismatches (sessionId, EIP-712, receipt hash)
- Watcher reconciliation gaps

Out of scope for v1: generic ERC-7579 modules, paymaster abuse, mainnet deployment issues.
