// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IRailguardAccountAdapter} from "./interfaces/IRailguardAccountAdapter.sol";
import {IRailguardExecutionHook} from "./interfaces/IRailguardExecutionHook.sol";
import {ExecutionDecoder} from "./libraries/ExecutionDecoder.sol";
import {RailguardErrors} from "./libraries/RailguardErrors.sol";
import {SessionId} from "./libraries/SessionId.sol";
import {SessionTypes} from "./libraries/SessionTypes.sol";

/// @title RailguardAccountAdapter
/// @notice V1 Railguard smart account with account-local session storage.
contract RailguardAccountAdapter is IRailguardAccountAdapter, EIP712, Ownable {
    bytes32 public constant SESSION_AUTHORIZATION_TYPEHASH = keccak256(
        "SessionAuthorization(address account,uint192 nonceKey,address sessionKey,address token,address allowedTarget,address allowedRecipient,bytes4 allowedSelector,uint256 maxPerTransfer,uint256 maxTotalSpend,uint48 validAfter,uint48 validUntil,bool allowBatch,bytes32 policyHash)"
    );

    address public immutable railguardSigner;
    IRailguardExecutionHook public immutable hook;

    mapping(address account => mapping(uint192 nonceKey => SessionTypes.SessionConfig)) internal sessions;

    event SessionRegistered(
        address indexed account,
        bytes32 indexed sessionId,
        uint192 indexed nonceKey,
        address sessionKey,
        address token,
        address allowedRecipient,
        uint256 maxTotalSpend,
        uint48 validUntil,
        bytes32 policyHash
    );

    event SessionRevoked(address indexed account, bytes32 indexed sessionId, uint192 indexed nonceKey);

    constructor(address owner_, address railguardSigner_, address hook_) EIP712("Railguard", "1") Ownable(owner_) {
        if (railguardSigner_ == address(0) || hook_ == address(0)) revert RailguardErrors.ZeroAddress();
        railguardSigner = railguardSigner_;
        hook = IRailguardExecutionHook(hook_);
    }

    function registerSession(
        SessionTypes.SessionConfig calldata config,
        bytes calldata ownerSig,
        bytes calldata railguardSig
    ) external {
        if (config.account != address(this)) revert RailguardErrors.InvalidAccount();
        _validateConfig(config);

        if (sessions[address(this)][config.nonceKey].account != address(0)) {
            revert RailguardErrors.SessionAlreadyExists();
        }

        bytes32 digest = _hashSessionAuthorization(config);
        if (ownerSig.length != 65) revert RailguardErrors.InvalidOwnerSignature();
        if (railguardSig.length != 65) revert RailguardErrors.InvalidRailguardSignature();

        address ownerSigner = ECDSA.recover(digest, ownerSig);
        if (ownerSigner != owner()) revert RailguardErrors.InvalidOwnerSignature();

        address railguardRecovered = ECDSA.recover(digest, railguardSig);
        if (railguardRecovered != railguardSigner) revert RailguardErrors.InvalidRailguardSignature();

        bytes32 expectedSessionId = SessionId.deriveSessionIdFromConfig(address(this), config);
        if (config.sessionId != expectedSessionId) revert RailguardErrors.InvalidSessionId();

        sessions[address(this)][config.nonceKey] = config;

        emit SessionRegistered(
            address(this),
            config.sessionId,
            config.nonceKey,
            config.sessionKey,
            config.token,
            config.allowedRecipient,
            config.maxTotalSpend,
            config.validUntil,
            config.policyHash
        );
    }

    function revokeSession(uint192 nonceKey) external onlyOwner {
        SessionTypes.SessionConfig storage session = sessions[address(this)][nonceKey];
        if (session.account == address(0)) revert RailguardErrors.SessionNotFound();
        session.revoked = true;
        emit SessionRevoked(address(this), session.sessionId, nonceKey);
    }

    function executeWithSession(uint192 nonceKey, bytes32 mode, bytes calldata executionCalldata) external {
        SessionTypes.SessionConfig memory session = sessions[address(this)][nonceKey];
        if (session.account == address(0)) revert RailguardErrors.SessionNotFound();
        if (session.revoked) revert RailguardErrors.SessionRevoked();
        if (block.timestamp < session.validAfter) revert RailguardErrors.SessionNotYetValid();
        if (block.timestamp > session.validUntil) revert RailguardErrors.SessionExpired();
        if (msg.sender != session.sessionKey && msg.sender != owner()) revert RailguardErrors.InvalidSessionKey();

        bytes memory hookData = hook.preCheck(address(this), nonceKey, mode, executionCalldata);
        _execute(mode, executionCalldata);
        hook.postCheck(hookData);
    }

    function getSession(address account, uint192 nonceKey) external view returns (SessionTypes.SessionConfig memory) {
        return sessions[account][nonceKey];
    }

    function buildSessionConfig(
        uint192 nonceKey,
        address sessionKey,
        address token,
        address allowedRecipient,
        uint256 maxPerTransfer,
        uint256 maxTotalSpend,
        uint48 validAfter,
        uint48 validUntil,
        bool allowBatch,
        bytes32 policyHash
    ) external view returns (SessionTypes.SessionConfig memory config) {
        config = SessionTypes.SessionConfig({
            sessionId: bytes32(0),
            policyHash: policyHash,
            account: address(this),
            sessionKey: sessionKey,
            token: token,
            allowedTarget: token,
            allowedRecipient: allowedRecipient,
            allowedSelector: SessionTypes.TRANSFER_SELECTOR,
            nonceKey: nonceKey,
            maxPerTransfer: maxPerTransfer,
            maxTotalSpend: maxTotalSpend,
            validAfter: validAfter,
            validUntil: validUntil,
            allowBatch: allowBatch,
            revoked: false
        });
        config.sessionId = SessionId.deriveSessionIdFromConfig(address(this), config);
    }

    function hashSessionAuthorization(SessionTypes.SessionConfig calldata config) external view returns (bytes32) {
        return _hashSessionAuthorization(config);
    }

    function _validateConfig(SessionTypes.SessionConfig calldata config) internal pure {
        if (config.sessionKey == address(0) || config.token == address(0)) revert RailguardErrors.ZeroAddress();
        if (config.allowedTarget != config.token) revert RailguardErrors.TargetMustEqualToken();
        if (config.allowedSelector != SessionTypes.TRANSFER_SELECTOR) revert RailguardErrors.UnsupportedSelector();
        if (config.maxPerTransfer == 0) revert RailguardErrors.InvalidSpendLimits();
        if (config.maxTotalSpend < config.maxPerTransfer) revert RailguardErrors.InvalidSpendLimits();
        if (config.validUntil <= config.validAfter) revert RailguardErrors.InvalidValidityWindow();
    }

    function _hashSessionAuthorization(SessionTypes.SessionConfig calldata config) internal view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    SESSION_AUTHORIZATION_TYPEHASH,
                    config.account,
                    config.nonceKey,
                    config.sessionKey,
                    config.token,
                    config.allowedTarget,
                    config.allowedRecipient,
                    config.allowedSelector,
                    config.maxPerTransfer,
                    config.maxTotalSpend,
                    config.validAfter,
                    config.validUntil,
                    config.allowBatch,
                    config.policyHash
                )
            )
        );
    }

    function _execute(bytes32 mode, bytes calldata executionCalldata) internal {
        if (mode == SessionTypes.CALLTYPE_SINGLE) {
            (address target, uint256 value, bytes memory callData) = ExecutionDecoder.decodeSingle(executionCalldata);
            _callWithERC20Check(target, value, callData);
            return;
        }
        if (mode == SessionTypes.CALLTYPE_BATCH) {
            SessionTypes.Execution[] memory executions = ExecutionDecoder.decodeBatch(executionCalldata);
            for (uint256 i = 0; i < executions.length; i++) {
                _callWithERC20Check(executions[i].target, executions[i].value, executions[i].callData);
            }
            return;
        }
        revert RailguardErrors.UnknownExecutionMode();
    }

    function _callWithERC20Check(address target, uint256 value, bytes memory callData) internal {
        (bool ok, bytes memory ret) = target.call{value: value}(callData);
        if (!ok) {
            if (ret.length > 0) {
                assembly {
                    revert(add(ret, 32), mload(ret))
                }
            }
            revert RailguardErrors.HookCallFailed();
        }
        if (ret.length > 0) {
            require(abi.decode(ret, (bool)), "ERC20_TRANSFER_FALSE");
        }
    }
}
