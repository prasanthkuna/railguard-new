// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {RailguardAccountAdapter} from "../src/RailguardAccountAdapter.sol";
import {RailguardExecutionHook} from "../src/RailguardExecutionHook.sol";
import {RailguardSessionValidator} from "../src/RailguardSessionValidator.sol";

/// @title Deploy
/// @notice Deploy Railguard v1 contracts.
contract Deploy is Script {
    function run() external returns (address adapter, address hook, address validator) {
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address owner = vm.envAddress("ACCOUNT_OWNER");
        address railguardSigner = vm.envAddress("RAILGUARD_SIGNER");
        require(owner != address(0), "ACCOUNT_OWNER required");
        require(railguardSigner != address(0), "RAILGUARD_SIGNER required");
        require(owner != railguardSigner, "owner and railguard signer must differ");

        vm.startBroadcast(deployerKey);

        hook = address(new RailguardExecutionHook());
        adapter = address(new RailguardAccountAdapter(owner, railguardSigner, hook));
        RailguardExecutionHook(hook).setAdapter(adapter);
        validator = address(new RailguardSessionValidator(adapter));

        vm.stopBroadcast();
    }
}
