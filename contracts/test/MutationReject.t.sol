// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RailguardTestBase} from "./RailguardTestBase.sol";
import {RailguardErrors} from "../src/libraries/RailguardErrors.sol";
import {SessionTypes} from "../src/libraries/SessionTypes.sol";

contract MutationRejectTest is RailguardTestBase {
    function setUp() public override {
        super.setUp();
        _register(false);
    }

    function test_mutated_target_reverts() public {
        address wrongToken = makeAddr("wrongToken");
        bytes memory execution = _singleExecution(wrongToken, recipient, 10e6);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.WrongTarget.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
    }

    function test_mutated_amount_reverts() public {
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.ExceedsMaxPerTransfer.selector);
        adapter.executeWithSession(
            NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, _singleExecution(address(usdc), recipient, maxPerTransfer + 1)
        );
    }

    function test_self_call_reverts() public {
        bytes memory callData = _transferCalldata(recipient, 1);
        bytes memory execution = abi.encodePacked(address(adapter), uint256(0), callData);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.SelfCallRejected.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
    }
}

contract SessionValidatorTest is RailguardTestBase {
    function test_validate_session_key_success() public {
        _register(false);
        bytes32 userOpHash = keccak256("userop");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sessionKeyPrivate, userOpHash);
        bytes memory sig = abi.encodePacked(r, s, v);
        assertTrue(validator.validateSessionKey(address(adapter), NONCE_KEY, userOpHash, sig));
    }

    function test_validate_session_key_wrong_signer() public {
        _register(false);
        bytes32 userOpHash = keccak256("userop");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, userOpHash);
        bytes memory sig = abi.encodePacked(r, s, v);
        assertFalse(validator.validateSessionKey(address(adapter), NONCE_KEY, userOpHash, sig));
    }
}
