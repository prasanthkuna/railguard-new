// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {RailguardAccountAdapter} from "../src/RailguardAccountAdapter.sol";
import {ExecutionDecoder} from "../src/libraries/ExecutionDecoder.sol";
import {SessionTypes} from "../src/libraries/SessionTypes.sol";

/// @notice Canonical E2E: on-chain session register (owner + SignGate cosign) + single USDC transfer.
contract E2eCanon is Script {
    function run() external {
        address adapterAddr = vm.envAddress("ADAPTER_ADDRESS");
        address usdcAddr = vm.envAddress("USDC_ADDRESS");
        bytes memory railguardSig = vm.envBytes("RAILGUARD_SIGNATURE");
        uint192 nonceKey = uint192(vm.envUint("NONCE_KEY"));

        address sessionKey = vm.envAddress("SESSION_KEY");
        address recipient = vm.envAddress("RECIPIENT");
        uint256 amount = vm.envUint("EXECUTE_AMOUNT");
        bytes32 policyHash = vm.envBytes32("POLICY_HASH");
        uint48 validAfter = uint48(vm.envUint("VALID_AFTER"));
        uint48 validUntil = uint48(vm.envUint("VALID_UNTIL"));

        uint256 ownerKey =
            vm.envOr("OWNER_PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        uint256 sessionKeyKey = vm.envOr(
            "SESSION_KEY_PRIVATE_KEY", uint256(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a)
        );

        RailguardAccountAdapter adapter = RailguardAccountAdapter(adapterAddr);
        SessionTypes.SessionConfig memory config = adapter.buildSessionConfig(
            nonceKey,
            sessionKey,
            usdcAddr,
            recipient,
            100_000_000,
            500_000_000,
            validAfter,
            validUntil,
            false,
            policyHash
        );

        bytes32 digest = adapter.hashSessionAuthorization(config);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, digest);
        bytes memory ownerSig = abi.encodePacked(r, s, v);

        vm.startBroadcast(ownerKey);
        adapter.registerSession(config, ownerSig, railguardSig);
        vm.stopBroadcast();

        bytes memory execution = ExecutionDecoder.encodeSingle(
            usdcAddr, 0, abi.encodeWithSelector(SessionTypes.TRANSFER_SELECTOR, recipient, amount)
        );

        vm.startBroadcast(sessionKeyKey);
        adapter.executeWithSession(nonceKey, SessionTypes.CALLTYPE_SINGLE, execution);
        vm.stopBroadcast();

        console2.log("E2E_SESSION_ID=", uint256(config.sessionId));
        console2.log("E2E_EXECUTE_AMOUNT=", amount);
    }
}
