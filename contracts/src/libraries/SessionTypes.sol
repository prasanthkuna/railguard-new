// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title SessionTypes
/// @notice Shared session and execution types for Railguard v1.
library SessionTypes {
    bytes32 internal constant CALLTYPE_SINGLE = bytes32(uint256(0x00));
    bytes32 internal constant CALLTYPE_BATCH = bytes32(uint256(0x01));
    bytes32 internal constant CALLTYPE_DELEGATE = bytes32(uint256(0xff));

    bytes4 internal constant TRANSFER_SELECTOR = 0xa9059cbb;

    struct SessionConfig {
        bytes32 sessionId;
        bytes32 policyHash;
        address account;
        address sessionKey;
        address token;
        address allowedTarget;
        address allowedRecipient;
        bytes4 allowedSelector;
        uint192 nonceKey;
        uint256 maxPerTransfer;
        uint256 maxTotalSpend;
        uint48 validAfter;
        uint48 validUntil;
        bool allowBatch;
        bool revoked;
    }

    struct Execution {
        address target;
        uint256 value;
        bytes callData;
    }
}
