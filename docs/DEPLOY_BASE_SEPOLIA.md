# Deploy to Base Sepolia (testnet)

Railguard v1 targets **Base Sepolia (chain ID 84532)** for testnet demos. Do not deploy to mainnet.

## Prerequisites

- Foundry installed
- Base Sepolia ETH on deployer account
- Distinct `ACCOUNT_OWNER` and `RAILGUARD_SIGNER` addresses

## Steps

```powershell
cd contracts

$env:DEPLOYER_PRIVATE_KEY = "0x..."   # funded deployer
$env:ACCOUNT_OWNER = "0x..."          # smart account owner
$env:RAILGUARD_SIGNER = "0x..."       # must differ from owner

forge script script/Deploy.s.sol:Deploy `
  --rpc-url https://sepolia.base.org `
  --broadcast `
  -vvvv
```

Record addresses from broadcast output:

| Contract | Address |
|----------|---------|
| RailguardExecutionHook | |
| RailguardAccountAdapter | |
| RailguardSessionValidator | |

## Post-deploy

1. Set `ADAPTER_ADDRESS` and `HOOK_ADDRESS` in SignGate env
2. Set `RPC_URL` to Base Sepolia
3. Run `powershell -File scripts/e2e-happy-path.ps1` against remote SignGate (optional)

## Example transcript

```text
==> Deploying Railguard to Base Sepolia
ADAPTER_ADDRESS= 0x...
HOOK_ADDRESS= 0x...
VALIDATOR_ADDRESS= 0x...
```
