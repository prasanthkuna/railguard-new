// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {RailguardAccountAdapter} from "../src/RailguardAccountAdapter.sol";
import {RailguardExecutionHook} from "../src/RailguardExecutionHook.sol";
import {RailguardSessionValidator} from "../src/RailguardSessionValidator.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";

/// @notice Anvil/local deploy — uses default anvil accounts 0 (owner) and 1 (railguard signer).
contract DeployLocal is Script {
    function run() external returns (address adapter, address hook, address validator, address usdc) {
        uint256 deployerKey = vm.envOr(
            "DEPLOYER_PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        address owner = vm.envOr("ACCOUNT_OWNER", vm.addr(deployerKey));
        address railguardSigner =
            vm.envOr("RAILGUARD_SIGNER", vm.addr(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d));

        vm.startBroadcast(deployerKey);

        hook = address(new RailguardExecutionHook());
        adapter = address(new RailguardAccountAdapter(owner, railguardSigner, hook));
        RailguardExecutionHook(hook).setAdapter(adapter);
        validator = address(new RailguardSessionValidator(adapter));

        usdc = address(new MockUSDC());
        MockUSDC(usdc).mint(adapter, 1_000_000e6);

        vm.stopBroadcast();

        console2.log("ADAPTER_ADDRESS=", adapter);
        console2.log("HOOK_ADDRESS=", hook);
        console2.log("VALIDATOR_ADDRESS=", validator);
        console2.log("USDC_ADDRESS=", usdc);
        console2.log("ACCOUNT_OWNER=", owner);
        console2.log("RAILGUARD_SIGNER=", railguardSigner);
    }
}
