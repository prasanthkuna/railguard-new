// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RailguardTestBase} from "./RailguardTestBase.sol";
import {RailguardErrors} from "../src/libraries/RailguardErrors.sol";
import {SessionTypes} from "../src/libraries/SessionTypes.sol";

contract SingleCallSpendTest is RailguardTestBase {
    function setUp() public override {
        super.setUp();
        _register(false);
    }

    function test_single_transfer_allowed() public {
        uint256 beforeBal = usdc.balanceOf(recipient);
        _executeSingle(50e6);
        assertEq(usdc.balanceOf(recipient), beforeBal + 50e6);
    }

    function test_single_transfer_wrong_recipient_reverts() public {
        bytes memory execution = _singleExecution(address(usdc), makeAddr("bad"), 10e6);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.WrongRecipient.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
    }

    function test_single_transfer_over_max_per_transfer_reverts() public {
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.ExceedsMaxPerTransfer.selector);
        adapter.executeWithSession(
            NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, _singleExecution(address(usdc), recipient, maxPerTransfer + 1)
        );
    }

    function test_single_transfer_updates_cumulative_spend() public {
        _executeSingle(40e6);
        SessionTypes.SessionConfig memory config = adapter.getSession(address(adapter), NONCE_KEY);
        assertEq(hook.sessionSpend(address(adapter), config.sessionId), 40e6);
    }

    function test_second_single_transfer_exceeding_session_cap_reverts() public {
        _executeSingle(90e6);
        _executeSingle(89e6);
        _executeSingle(88e6);
        _executeSingle(87e6);
        _executeSingle(86e6);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.ExceedsMaxTotalSpend.selector);
        adapter.executeWithSession(
            NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, _singleExecution(address(usdc), recipient, 61e6)
        );
    }
}
