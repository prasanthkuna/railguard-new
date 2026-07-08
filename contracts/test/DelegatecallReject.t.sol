// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RailguardTestBase} from "./RailguardTestBase.sol";
import {RailguardErrors} from "../src/libraries/RailguardErrors.sol";
import {SessionTypes} from "../src/libraries/SessionTypes.sol";

contract DelegatecallRejectTest is RailguardTestBase {
    function setUp() public override {
        super.setUp();
        _register(false);
    }

    function test_delegatecall_reverts() public {
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.DelegatecallRejected.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_DELEGATE, bytes(""));
    }

    function test_unknown_mode_reverts() public {
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.UnknownExecutionMode.selector);
        adapter.executeWithSession(NONCE_KEY, bytes32(uint256(0x99)), bytes(""));
    }

    function test_approve_reverts() public {
        bytes memory callData = abi.encodeWithSelector(0x095ea7b3, recipient, 1);
        bytes memory execution = _singleExecution(address(usdc), address(usdc), 0);
        execution = _singleExecution(address(usdc), address(usdc), 0);
        execution = abi.encodePacked(address(usdc), uint256(0), callData);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.UnsupportedSelector.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
    }
}
