// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RailguardTestBase} from "./RailguardTestBase.sol";
import {RailguardErrors} from "../src/libraries/RailguardErrors.sol";
import {SessionId} from "../src/libraries/SessionId.sol";
import {SessionTypes} from "../src/libraries/SessionTypes.sol";

contract SessionRegistrationTest is RailguardTestBase {
    function test_register_valid_session_dual_sig() public {
        SessionTypes.SessionConfig memory config = _register(false);
        SessionTypes.SessionConfig memory stored = adapter.getSession(address(adapter), NONCE_KEY);
        assertEq(stored.sessionId, config.sessionId);
        assertEq(stored.sessionKey, sessionKey);
    }

    function test_reject_registration_without_owner_sig() public {
        SessionTypes.SessionConfig memory config = _buildConfig(false);
        (, bytes memory railguardSig) = _signatures(config);
        vm.expectRevert(RailguardErrors.InvalidOwnerSignature.selector);
        adapter.registerSession(config, bytes(""), railguardSig);
    }

    function test_reject_registration_without_railguard_sig() public {
        SessionTypes.SessionConfig memory config = _buildConfig(false);
        (bytes memory ownerSig,) = _signatures(config);
        vm.expectRevert(RailguardErrors.InvalidRailguardSignature.selector);
        adapter.registerSession(config, ownerSig, bytes(""));
    }

    function test_reject_allowed_target_not_equal_token() public {
        SessionTypes.SessionConfig memory config = _buildConfig(false);
        config.allowedTarget = makeAddr("wrong");
        (bytes memory ownerSig, bytes memory railguardSig) = _signatures(config);
        vm.expectRevert(RailguardErrors.TargetMustEqualToken.selector);
        adapter.registerSession(config, ownerSig, railguardSig);
    }

    function test_reject_duplicate_nonce_key() public {
        _register(false);
        SessionTypes.SessionConfig memory config = _buildConfig(false);
        (bytes memory ownerSig, bytes memory railguardSig) = _signatures(config);
        vm.expectRevert(RailguardErrors.SessionAlreadyExists.selector);
        adapter.registerSession(config, ownerSig, railguardSig);
    }

    function test_session_id_derivation_matches_offchain_formula() public view {
        SessionTypes.SessionConfig memory config = _buildConfig(true);
        bytes32 physical = SessionId.sessionConfigPhysicalHash(config);
        bytes32 expected = SessionId.deriveSessionId(address(adapter), address(adapter), NONCE_KEY, physical);
        assertEq(config.sessionId, expected);
    }

    function test_revoke_session() public {
        SessionTypes.SessionConfig memory config = _register(false);
        vm.prank(owner);
        adapter.revokeSession(NONCE_KEY);
        SessionTypes.SessionConfig memory stored = adapter.getSession(address(adapter), NONCE_KEY);
        assertTrue(stored.revoked);
        assertEq(stored.sessionId, config.sessionId);
    }
}
