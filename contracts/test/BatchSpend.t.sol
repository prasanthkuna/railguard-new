// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RailguardTestBase} from "./RailguardTestBase.sol";
import {RailguardErrors} from "../src/libraries/RailguardErrors.sol";
import {ExecutionDecoder} from "../src/libraries/ExecutionDecoder.sol";
import {SessionTypes} from "../src/libraries/SessionTypes.sol";

contract BatchSpendTest is RailguardTestBase {
    function test_batch_all_valid_allowed() public {
        _register(true);
        SessionTypes.Execution[] memory leaves = new SessionTypes.Execution[](2);
        leaves[0] = SessionTypes.Execution(address(usdc), 0, _transferCalldata(recipient, 20e6));
        leaves[1] = SessionTypes.Execution(address(usdc), 0, _transferCalldata(recipient, 30e6));
        bytes memory execution = ExecutionDecoder.encodeBatch(leaves);
        vm.prank(sessionKey);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_BATCH, execution);
        assertEq(usdc.balanceOf(recipient), 50e6);
    }

    function test_batch_one_bad_leaf_reverts() public {
        _register(true);
        SessionTypes.Execution[] memory leaves = new SessionTypes.Execution[](2);
        leaves[0] = SessionTypes.Execution(address(usdc), 0, _transferCalldata(recipient, 20e6));
        leaves[1] = SessionTypes.Execution(address(usdc), 0, _transferCalldata(makeAddr("bad"), 10e6));
        bytes memory execution = ExecutionDecoder.encodeBatch(leaves);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.WrongRecipient.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_BATCH, execution);
    }

    function test_batch_rejected_when_allow_batch_false() public {
        _register(false);
        SessionTypes.Execution[] memory leaves = new SessionTypes.Execution[](1);
        leaves[0] = SessionTypes.Execution(address(usdc), 0, _transferCalldata(recipient, 10e6));
        bytes memory execution = ExecutionDecoder.encodeBatch(leaves);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.BatchNotAllowed.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_BATCH, execution);
    }
}
