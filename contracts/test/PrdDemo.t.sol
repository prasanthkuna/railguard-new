// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {RailguardTestBase} from "./RailguardTestBase.sol";
import {RailguardErrors} from "../src/libraries/RailguardErrors.sol";
import {ExecutionDecoder} from "../src/libraries/ExecutionDecoder.sol";
import {SessionTypes} from "../src/libraries/SessionTypes.sol";

/// @notice PRD demo: one allowed payment + three blocked attacks (run via forge test --match-contract PrdDemoTest -vv).
contract PrdDemoTest is RailguardTestBase {
    function test_demo_allowed_transfer() public {
        _register(false);
        uint256 before = usdc.balanceOf(recipient);
        _executeSingle(50e6);
        uint256 afterBal = usdc.balanceOf(recipient);
        console2.log("DEMO_ALLOW: recipient received", afterBal - before);
        assertEq(afterBal - before, 50e6);
    }

    function test_demo_block_wrong_recipient() public {
        _register(false);
        bytes memory execution = _singleExecution(address(usdc), attacker, 10e6);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.WrongRecipient.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
        console2.log("DEMO_BLOCK: wrong recipient rejected");
    }

    function test_demo_block_batch_injection() public {
        _register(true);
        SessionTypes.Execution[] memory leaves = new SessionTypes.Execution[](2);
        leaves[0] = SessionTypes.Execution(address(usdc), 0, _transferCalldata(recipient, 10e6));
        leaves[1] = SessionTypes.Execution(address(usdc), 0, _transferCalldata(attacker, 10e6));
        bytes memory batch = ExecutionDecoder.encodeBatch(leaves);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.WrongRecipient.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_BATCH, batch);
        console2.log("DEMO_BLOCK: malicious batch leaf rejected");
    }

    function test_demo_block_cumulative_cap() public {
        _register(false);
        _executeSingle(100e6);
        _executeSingle(99e6);
        _executeSingle(98e6);
        _executeSingle(97e6);
        _executeSingle(96e6);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.ExceedsMaxTotalSpend.selector);
        adapter.executeWithSession(
            NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, _singleExecution(address(usdc), recipient, 11e6)
        );
        console2.log("DEMO_BLOCK: cumulative session cap rejected");
    }
}
