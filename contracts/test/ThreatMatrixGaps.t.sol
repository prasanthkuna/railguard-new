// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RailguardTestBase} from "./RailguardTestBase.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {RailguardErrors} from "../src/libraries/RailguardErrors.sol";
import {ExecutionDecoder} from "../src/libraries/ExecutionDecoder.sol";
import {SessionTypes} from "../src/libraries/SessionTypes.sol";

/// @notice TRD §21 gap coverage — registration, execution, and selector rejects.
contract ThreatMatrixGapsTest is RailguardTestBase {
    MockUSDC internal otherToken;

    function setUp() public override {
        super.setUp();
        otherToken = new MockUSDC();
    }

    // --- Registration gaps ---

    function test_reject_zero_session_key() public {
        SessionTypes.SessionConfig memory config = _buildConfig(false);
        config.sessionKey = address(0);
        config.sessionId =
        adapter.buildSessionConfig(
            config.nonceKey,
            config.sessionKey,
            config.token,
            config.allowedRecipient,
            config.maxPerTransfer,
            config.maxTotalSpend,
            config.validAfter,
            config.validUntil,
            config.allowBatch,
            config.policyHash
        )
        .sessionId;
        (bytes memory ownerSig, bytes memory railguardSig) = _signatures(config);
        vm.expectRevert(RailguardErrors.ZeroAddress.selector);
        adapter.registerSession(config, ownerSig, railguardSig);
    }

    function test_reject_zero_token() public {
        SessionTypes.SessionConfig memory config = _buildConfig(false);
        config.token = address(0);
        config.allowedTarget = address(0);
        config.sessionId =
        adapter.buildSessionConfig(
            config.nonceKey,
            config.sessionKey,
            config.token,
            config.allowedRecipient,
            config.maxPerTransfer,
            config.maxTotalSpend,
            config.validAfter,
            config.validUntil,
            config.allowBatch,
            config.policyHash
        )
        .sessionId;
        (bytes memory ownerSig, bytes memory railguardSig) = _signatures(config);
        vm.expectRevert(RailguardErrors.ZeroAddress.selector);
        adapter.registerSession(config, ownerSig, railguardSig);
    }

    function test_reject_invalid_validity_window() public {
        SessionTypes.SessionConfig memory config = _buildConfig(false);
        config.validAfter = uint48(block.timestamp + 1 days);
        config.validUntil = uint48(block.timestamp);
        config.sessionId =
        adapter.buildSessionConfig(
            config.nonceKey,
            config.sessionKey,
            config.token,
            config.allowedRecipient,
            config.maxPerTransfer,
            config.maxTotalSpend,
            config.validAfter,
            config.validUntil,
            config.allowBatch,
            config.policyHash
        )
        .sessionId;
        (bytes memory ownerSig, bytes memory railguardSig) = _signatures(config);
        vm.expectRevert(RailguardErrors.InvalidValidityWindow.selector);
        adapter.registerSession(config, ownerSig, railguardSig);
    }

    function test_reject_max_total_below_max_per_transfer() public {
        SessionTypes.SessionConfig memory config = _buildConfig(false);
        config.maxPerTransfer = 200e6;
        config.maxTotalSpend = 100e6;
        config.sessionId =
        adapter.buildSessionConfig(
            config.nonceKey,
            config.sessionKey,
            config.token,
            config.allowedRecipient,
            config.maxPerTransfer,
            config.maxTotalSpend,
            config.validAfter,
            config.validUntil,
            config.allowBatch,
            config.policyHash
        )
        .sessionId;
        (bytes memory ownerSig, bytes memory railguardSig) = _signatures(config);
        vm.expectRevert(RailguardErrors.InvalidSpendLimits.selector);
        adapter.registerSession(config, ownerSig, railguardSig);
    }

    function test_reject_revoked_session_execution() public {
        _register(false);
        vm.prank(owner);
        adapter.revokeSession(NONCE_KEY);
        bytes memory execution = _singleExecution(address(usdc), recipient, 10e6);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.SessionRevoked.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
    }

    function test_reject_session_key_registering_without_owner_sig() public {
        SessionTypes.SessionConfig memory config = _buildConfig(false);
        (, bytes memory railguardSig) = _signatures(config);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.InvalidOwnerSignature.selector);
        adapter.registerSession(config, bytes(""), railguardSig);
    }

    // --- Single-call gaps ---

    function test_single_transfer_wrong_token_reverts() public {
        _register(false);
        bytes memory execution = _singleExecution(address(otherToken), recipient, 10e6);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.WrongTarget.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
    }

    function test_single_transfer_wrong_target_reverts() public {
        _register(false);
        bytes memory execution = _singleExecution(makeAddr("wrongTarget"), recipient, 10e6);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.WrongTarget.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
    }

    function test_single_transfer_wrong_selector_reverts() public {
        _register(false);
        bytes memory callData = abi.encodeWithSelector(0xdeadbeef, recipient, 10e6);
        bytes memory execution = abi.encodePacked(address(usdc), uint256(0), callData);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.UnsupportedSelector.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
    }

    function test_wrong_nonce_lane_reverts() public {
        _register(false);
        bytes memory execution = _singleExecution(address(usdc), recipient, 10e6);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.SessionNotFound.selector);
        adapter.executeWithSession(NONCE_KEY + 1, SessionTypes.CALLTYPE_SINGLE, execution);
    }

    // --- Execution mode gaps ---

    function test_native_eth_transfer_reverts() public {
        _register(false);
        bytes memory callData = _transferCalldata(recipient, 1);
        bytes memory execution = abi.encodePacked(address(usdc), uint256(1 ether), callData);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.NativeEthRejected.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
    }

    function test_transfer_from_reverts() public {
        _register(false);
        bytes memory callData = abi.encodeWithSelector(0x23b872dd, owner, recipient, 1);
        bytes memory execution = abi.encodePacked(address(usdc), uint256(0), callData);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.UnsupportedSelector.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
    }

    function test_permit_reverts() public {
        _register(false);
        bytes memory callData = abi.encodeWithSelector(0xd505accf, owner, recipient, 1, 0, 0, 0, bytes32(0), bytes32(0));
        bytes memory execution = abi.encodePacked(address(usdc), uint256(0), callData);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.UnsupportedSelector.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
    }

    function test_mutated_selector_reverts() public {
        _register(false);
        bytes memory callData = abi.encodeWithSelector(0xa9059cbb, recipient, 10e6);
        callData[0] = bytes1(uint8(0xbb));
        bytes memory execution = abi.encodePacked(address(usdc), uint256(0), callData);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.UnsupportedSelector.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
    }

    // --- Batch gaps ---

    function test_batch_wrong_recipient_reverts() public {
        _register(true);
        SessionTypes.Execution[] memory leaves = new SessionTypes.Execution[](2);
        leaves[0] = SessionTypes.Execution(address(usdc), 0, _transferCalldata(recipient, 10e6));
        leaves[1] = SessionTypes.Execution(address(usdc), 0, _transferCalldata(attacker, 10e6));
        bytes memory batch = ExecutionDecoder.encodeBatch(leaves);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.WrongRecipient.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_BATCH, batch);
    }

    function test_batch_wrong_token_reverts() public {
        _register(true);
        SessionTypes.Execution[] memory leaves = new SessionTypes.Execution[](2);
        leaves[0] = SessionTypes.Execution(address(usdc), 0, _transferCalldata(recipient, 10e6));
        leaves[1] = SessionTypes.Execution(address(otherToken), 0, _transferCalldata(recipient, 10e6));
        bytes memory batch = ExecutionDecoder.encodeBatch(leaves);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.WrongTarget.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_BATCH, batch);
    }

    function test_batch_over_max_per_transfer_reverts() public {
        _register(true);
        SessionTypes.Execution[] memory leaves = new SessionTypes.Execution[](1);
        leaves[0] = SessionTypes.Execution(address(usdc), 0, _transferCalldata(recipient, maxPerTransfer + 1));
        bytes memory batch = ExecutionDecoder.encodeBatch(leaves);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.ExceedsMaxPerTransfer.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_BATCH, batch);
    }
}
