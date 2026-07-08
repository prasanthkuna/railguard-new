// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RailguardTestBase} from "./RailguardTestBase.sol";
import {RailguardErrors} from "../src/libraries/RailguardErrors.sol";
import {SessionTypes} from "../src/libraries/SessionTypes.sol";

/// @notice Mirrors fixtures/physical_vectors.json hookAllows=false cases on-chain.
contract PhysicalVectorTest is RailguardTestBase {
    function setUp() public override {
        super.setUp();
        _register(false);
    }

    function test_vector_blocked_over_max_per_transfer() public {
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.ExceedsMaxPerTransfer.selector);
        adapter.executeWithSession(
            NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, _singleExecution(address(usdc), recipient, 200e6)
        );
    }

    function test_vector_blocked_wrong_recipient() public {
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.WrongRecipient.selector);
        adapter.executeWithSession(
            NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, _singleExecution(address(usdc), attacker, 50e6)
        );
    }

    function test_vector_allowed_within_limits() public {
        vm.prank(sessionKey);
        adapter.executeWithSession(
            NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, _singleExecution(address(usdc), recipient, 50e6)
        );
        assertEq(usdc.balanceOf(recipient), 50e6);
    }
}
