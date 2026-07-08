// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {RailguardAccountAdapter} from "../src/RailguardAccountAdapter.sol";
import {RailguardExecutionHook} from "../src/RailguardExecutionHook.sol";
import {RailguardSessionValidator} from "../src/RailguardSessionValidator.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {ExecutionDecoder} from "../src/libraries/ExecutionDecoder.sol";
import {SessionId} from "../src/libraries/SessionId.sol";
import {SessionTypes} from "../src/libraries/SessionTypes.sol";

abstract contract RailguardTestBase is Test {
    uint192 internal constant NONCE_KEY = 12345;

    uint256 internal ownerPrivateKey = 0x1;
    address internal owner;
    uint256 internal railguardSignerKey = 0xA11CE;
    address internal railguardSigner;
    uint256 internal sessionKeyPrivate = 0xB0B;
    address internal sessionKey;
    address internal recipient;
    address internal attacker = makeAddr("attacker");

    MockUSDC internal usdc;
    RailguardExecutionHook internal hook;
    RailguardAccountAdapter internal adapter;
    RailguardSessionValidator internal validator;

    uint256 internal maxPerTransfer = 100e6;
    uint256 internal maxTotalSpend = 500e6;

    function setUp() public virtual {
        owner = vm.addr(ownerPrivateKey);
        railguardSigner = vm.addr(railguardSignerKey);
        sessionKey = vm.addr(sessionKeyPrivate);
        recipient = makeAddr("recipient");

        usdc = new MockUSDC();
        hook = new RailguardExecutionHook();
        adapter = new RailguardAccountAdapter(owner, railguardSigner, address(hook));
        hook.setAdapter(address(adapter));
        validator = new RailguardSessionValidator(address(adapter));
        usdc.mint(address(adapter), 1_000_000e6);
    }

    function _buildConfig(bool allowBatch) internal view returns (SessionTypes.SessionConfig memory) {
        return adapter.buildSessionConfig(
            NONCE_KEY,
            sessionKey,
            address(usdc),
            recipient,
            maxPerTransfer,
            maxTotalSpend,
            uint48(block.timestamp - 1),
            uint48(block.timestamp + 1 days),
            allowBatch,
            keccak256("policy.v1")
        );
    }

    function _signatures(SessionTypes.SessionConfig memory config)
        internal
        view
        returns (bytes memory ownerSig, bytes memory railguardSig)
    {
        bytes32 digest = adapter.hashSessionAuthorization(config);
        (uint8 ov, bytes32 orv, bytes32 ot) = vm.sign(ownerPrivateKey, digest);
        (uint8 rv, bytes32 rrv, bytes32 rt) = vm.sign(railguardSignerKey, digest);
        ownerSig = abi.encodePacked(orv, ot, ov);
        railguardSig = abi.encodePacked(rrv, rt, rv);
    }

    function _register(bool allowBatch) internal returns (SessionTypes.SessionConfig memory config) {
        config = _buildConfig(allowBatch);
        (bytes memory ownerSig, bytes memory railguardSig) = _signatures(config);
        adapter.registerSession(config, ownerSig, railguardSig);
    }

    function _transferCalldata(address to, uint256 amount) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(SessionTypes.TRANSFER_SELECTOR, to, amount);
    }

    function _singleExecution(address token, address to, uint256 amount) internal pure returns (bytes memory) {
        return ExecutionDecoder.encodeSingle(token, 0, _transferCalldata(to, amount));
    }

    function _executeSingle(uint256 amount) internal {
        bytes memory execution = _singleExecution(address(usdc), recipient, amount);
        vm.prank(sessionKey);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_SINGLE, execution);
    }
}
