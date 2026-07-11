// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RailguardTestBase} from "./RailguardTestBase.sol";
import {RailguardErrors} from "../src/libraries/RailguardErrors.sol";
import {SessionTypes} from "../src/libraries/SessionTypes.sol";

contract ReplayRejectTest is RailguardTestBase {
    function setUp() public override {
        super.setUp();
        _register(false);
    }

    function test_identical_calldata_allowed_with_monotonic_sequence() public {
        bytes memory execution = _singleExecution(address(usdc), recipient, 10e6);
        vm.prank(sessionKey);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
        vm.prank(sessionKey);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
    }
}

contract ExpiryRejectTest is RailguardTestBase {
    function test_expired_session_reverts() public {
        vm.warp(10 days);
        SessionTypes.SessionConfig memory config = adapter.buildSessionConfig(
            NONCE_KEY,
            sessionKey,
            address(usdc),
            recipient,
            maxPerTransfer,
            maxTotalSpend,
            uint48(1 days),
            uint48(2 days),
            false,
            keccak256("policy.v1")
        );
        (bytes memory ownerSig, bytes memory railguardSig) = _signatures(config);
        adapter.registerSession(config, ownerSig, railguardSig);
        vm.warp(3 days);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.SessionExpired.selector);
        adapter.executeWithSession(
            NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, _singleExecution(address(usdc), recipient, 1e6)
        );
    }

    function test_not_yet_valid_session_reverts() public {
        vm.warp(10 days);
        SessionTypes.SessionConfig memory config = adapter.buildSessionConfig(
            NONCE_KEY,
            sessionKey,
            address(usdc),
            recipient,
            maxPerTransfer,
            maxTotalSpend,
            uint48(20 days),
            uint48(30 days),
            false,
            keccak256("policy.v1")
        );
        (bytes memory ownerSig, bytes memory railguardSig) = _signatures(config);
        adapter.registerSession(config, ownerSig, railguardSig);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.SessionNotYetValid.selector);
        adapter.executeWithSession(
            NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, _singleExecution(address(usdc), recipient, 1e6)
        );
    }
}
