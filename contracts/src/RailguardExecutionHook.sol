// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRailguardAccountAdapter} from "./interfaces/IRailguardAccountAdapter.sol";
import {IRailguardExecutionHook} from "./interfaces/IRailguardExecutionHook.sol";
import {ExecutionDecoder} from "./libraries/ExecutionDecoder.sol";
import {RailguardErrors} from "./libraries/RailguardErrors.sol";
import {SessionId} from "./libraries/SessionId.sol";
import {SessionTypes} from "./libraries/SessionTypes.sol";

/// @title RailguardExecutionHook
/// @notice Physical on-chain enforcement boundary for Railguard v1.
contract RailguardExecutionHook is IRailguardExecutionHook {
    address public immutable deployer;
    address public adapter;
    bool private _adapterSet;

    mapping(address account => mapping(bytes32 sessionId => uint256 spent)) public sessionSpend;
    mapping(address account => mapping(bytes32 digest => bool used)) public usedExecutions;

    event ExecutionAllowed(
        address indexed account,
        bytes32 indexed sessionId,
        uint192 indexed nonceKey,
        uint256 frameSpend,
        uint256 totalSpendAfter
    );

    event ExecutionBlocked(address indexed account, bytes32 indexed sessionId, string reason);

    struct HookContext {
        address account;
        bytes32 sessionId;
        uint192 nonceKey;
        bytes32 executionDigest;
        uint256 frameSpend;
        uint256 maxTotalSpend;
        bool applied;
    }

    constructor() {
        deployer = msg.sender;
    }

    function setAdapter(address adapter_) external {
        if (msg.sender != deployer) revert RailguardErrors.Unauthorized();
        if (_adapterSet) revert RailguardErrors.Unauthorized();
        if (adapter_ == address(0)) revert RailguardErrors.ZeroAddress();
        adapter = adapter_;
        _adapterSet = true;
    }

    function preCheck(address account, uint192 nonceKey, bytes32 mode, bytes calldata executionCalldata)
        external
        returns (bytes memory hookData)
    {
        if (msg.sender != adapter) revert RailguardErrors.Unauthorized();

        SessionTypes.SessionConfig memory session = IRailguardAccountAdapter(adapter).getSession(account, nonceKey);
        _requireActiveSession(session);

        bytes32 digest = _executionDigest(account, session.sessionId, nonceKey, mode, executionCalldata);
        if (usedExecutions[account][digest]) revert RailguardErrors.ExecutionReplayed();

        uint256 frameSpend = _validateFrame(session, account, mode, executionCalldata);

        uint256 currentSpend = sessionSpend[account][session.sessionId];
        if (currentSpend + frameSpend > session.maxTotalSpend) {
            emit ExecutionBlocked(account, session.sessionId, "EXCEEDS_MAX_TOTAL_SPEND");
            revert RailguardErrors.ExceedsMaxTotalSpend();
        }

        hookData = abi.encode(
            HookContext({
                account: account,
                sessionId: session.sessionId,
                nonceKey: nonceKey,
                executionDigest: digest,
                frameSpend: frameSpend,
                maxTotalSpend: session.maxTotalSpend,
                applied: false
            })
        );
    }

    function postCheck(bytes calldata hookData) external {
        if (msg.sender != adapter) revert RailguardErrors.Unauthorized();

        HookContext memory ctx = abi.decode(hookData, (HookContext));
        if (ctx.applied) revert RailguardErrors.ExecutionReplayed();
        if (usedExecutions[ctx.account][ctx.executionDigest]) revert RailguardErrors.ExecutionReplayed();

        uint256 newSpend = sessionSpend[ctx.account][ctx.sessionId] + ctx.frameSpend;
        if (newSpend > ctx.maxTotalSpend) revert RailguardErrors.ExceedsMaxTotalSpend();

        sessionSpend[ctx.account][ctx.sessionId] = newSpend;
        usedExecutions[ctx.account][ctx.executionDigest] = true;

        emit ExecutionAllowed(ctx.account, ctx.sessionId, ctx.nonceKey, ctx.frameSpend, newSpend);
    }

    function executionDigest(
        address account,
        bytes32 sessionId,
        uint192 nonceKey,
        bytes32 mode,
        bytes calldata executionCalldata
    ) external view returns (bytes32) {
        return _executionDigest(account, sessionId, nonceKey, mode, executionCalldata);
    }

    function _executionDigest(
        address account,
        bytes32 sessionId,
        uint192 nonceKey,
        bytes32 mode,
        bytes calldata executionCalldata
    ) internal view returns (bytes32) {
        return keccak256(
            abi.encode(block.chainid, address(this), account, sessionId, nonceKey, mode, keccak256(executionCalldata))
        );
    }

    function _requireActiveSession(SessionTypes.SessionConfig memory session) internal view {
        if (session.account == address(0)) revert RailguardErrors.SessionNotFound();
        if (session.revoked) revert RailguardErrors.SessionRevoked();
        if (block.timestamp < session.validAfter) revert RailguardErrors.SessionNotYetValid();
        if (block.timestamp > session.validUntil) revert RailguardErrors.SessionExpired();
    }

    function _validateFrame(
        SessionTypes.SessionConfig memory session,
        address account,
        bytes32 mode,
        bytes calldata executionCalldata
    ) internal returns (uint256 frameSpend) {
        if (mode == SessionTypes.CALLTYPE_DELEGATE) {
            emit ExecutionBlocked(account, session.sessionId, "DELEGATECALL");
            revert RailguardErrors.DelegatecallRejected();
        }
        if (mode == SessionTypes.CALLTYPE_SINGLE) {
            (address target, uint256 value, bytes memory callData) = ExecutionDecoder.decodeSingle(executionCalldata);
            frameSpend += _validateLeaf(session, account, target, value, callData);
            return frameSpend;
        }
        if (mode == SessionTypes.CALLTYPE_BATCH) {
            if (!session.allowBatch) {
                emit ExecutionBlocked(account, session.sessionId, "BATCH_NOT_ALLOWED");
                revert RailguardErrors.BatchNotAllowed();
            }
            SessionTypes.Execution[] memory executions = ExecutionDecoder.decodeBatch(executionCalldata);
            for (uint256 i = 0; i < executions.length; i++) {
                frameSpend += _validateLeaf(
                    session, account, executions[i].target, executions[i].value, executions[i].callData
                );
            }
            return frameSpend;
        }

        emit ExecutionBlocked(account, session.sessionId, "UNKNOWN_MODE");
        revert RailguardErrors.UnknownExecutionMode();
    }

    function _validateLeaf(
        SessionTypes.SessionConfig memory session,
        address account,
        address target,
        uint256 value,
        bytes memory callData
    ) internal returns (uint256 amount) {
        if (target == address(0)) revert RailguardErrors.WrongTarget();
        if (target == account) {
            emit ExecutionBlocked(account, session.sessionId, "SELF_CALL");
            revert RailguardErrors.SelfCallRejected();
        }
        if (value != 0) {
            emit ExecutionBlocked(account, session.sessionId, "NATIVE_ETH");
            revert RailguardErrors.NativeEthRejected();
        }
        if (session.allowedTarget != session.token) revert RailguardErrors.TargetMustEqualToken();
        if (target != session.allowedTarget) {
            emit ExecutionBlocked(account, session.sessionId, "WRONG_TARGET");
            revert RailguardErrors.WrongTarget();
        }
        if (callData.length < 4) revert RailguardErrors.UnsupportedSelector();

        bytes4 selector = bytes4(callData);
        if (selector != SessionTypes.TRANSFER_SELECTOR) {
            if (selector == 0x095ea7b3 || selector == 0x23b872dd || selector == 0xd505accf || selector == 0x2e1a7d4d) {
                emit ExecutionBlocked(account, session.sessionId, "UNSUPPORTED_SELECTOR");
                revert RailguardErrors.UnsupportedSelector();
            }
            emit ExecutionBlocked(account, session.sessionId, "UNKNOWN_SELECTOR");
            revert RailguardErrors.UnsupportedSelector();
        }
        if (selector != session.allowedSelector) revert RailguardErrors.UnsupportedSelector();

        (address recipient, uint256 transferAmount) = abi.decode(_slice(callData, 4), (address, uint256));
        if (recipient != session.allowedRecipient) {
            emit ExecutionBlocked(account, session.sessionId, "WRONG_RECIPIENT");
            revert RailguardErrors.WrongRecipient();
        }
        if (transferAmount > session.maxPerTransfer) {
            emit ExecutionBlocked(account, session.sessionId, "EXCEEDS_MAX_PER_TRANSFER");
            revert RailguardErrors.ExceedsMaxPerTransfer();
        }

        return transferAmount;
    }

    function _slice(bytes memory data, uint256 start) internal pure returns (bytes memory result) {
        result = new bytes(data.length - start);
        for (uint256 i = 0; i < result.length; i++) {
            result[i] = data[start + i];
        }
    }
}
