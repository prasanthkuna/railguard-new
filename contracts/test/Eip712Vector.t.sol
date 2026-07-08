// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {RailguardAccountAdapter} from "../src/RailguardAccountAdapter.sol";
import {RailguardExecutionHook} from "../src/RailguardExecutionHook.sol";
import {SessionTypes} from "../src/libraries/SessionTypes.sol";

/// @notice Fixed cross-language EIP-712 SessionAuthorization digest vector.
contract Eip712VectorTest is Test {
    address internal constant OWNER = address(0xA);
    address internal constant RAILGUARD_SIGNER = address(0xB);
    address internal constant ACCOUNT = address(0x1);
    address internal constant SESSION_KEY = address(0x2);

    function test_export_eip712_digest_vector() public {
        vm.chainId(84532);

        RailguardExecutionHook hook = new RailguardExecutionHook();
        RailguardAccountAdapter adapter = new RailguardAccountAdapter(OWNER, RAILGUARD_SIGNER, address(hook));
        hook.setAdapter(address(adapter));

        SessionTypes.SessionConfig memory config = SessionTypes.SessionConfig({
            sessionId: bytes32(0),
            policyHash: bytes32(uint256(0x11)),
            account: ACCOUNT,
            sessionKey: SESSION_KEY,
            token: address(0xaa),
            allowedTarget: address(0xaa),
            allowedRecipient: address(0xb01),
            allowedSelector: SessionTypes.TRANSFER_SELECTOR,
            nonceKey: 12345,
            maxPerTransfer: 100_000_000,
            maxTotalSpend: 500_000_000,
            validAfter: 1,
            validUntil: 9_999_999_999,
            allowBatch: false,
            revoked: false
        });

        bytes32 digest = adapter.hashSessionAuthorization(config);
        console2.logAddress(address(adapter));
        console2.logBytes32(digest);
        assertEq(digest, 0xe500012fc5fb6423b2c95575f276c554190b953c054f9183465e2783d5bfa7a1);
    }
}
