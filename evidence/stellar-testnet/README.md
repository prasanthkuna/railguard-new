# Stellar testnet — live payment evidence

## Summary

| Field | Value |
|-------|-------|
| Network | Stellar testnet |
| Tx hash | `3dc3225844f711f9f96ead65690d224b7ccfd616d1da5387df6bfc63bfb8e437` |
| Explorer | [stellar.expert](https://stellar.expert/explorer/testnet/tx/3dc3225844f711f9f96ead65690d224b7ccfd616d1da5387df6bfc63bfb8e437) |
| Intent | `pi-testnet-evidence` |
| Settlement | CONFIRMED (memo-bound) |

## Reproduce

```bash
cd stellar-payment-assurance-kit
npm install
npm run testnet-evidence
```

Verify existing tx (read-only):

```bash
STELLAR_TX_HASH=3dc3225844f711f9f96ead65690d224b7ccfd616d1da5387df6bfc63bfb8e437 \
  npm run testnet-verify
```

## Profiles

SPA-001 through SPA-005 in `packages/runner` — see repo README.
