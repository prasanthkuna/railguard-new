// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title RailguardErrors
/// @notice Custom errors for Railguard contracts.
library RailguardErrors {
    error ZeroAddress();
    error InvalidValidityWindow();
    error InvalidSpendLimits();
    error TargetMustEqualToken();
    error SessionAlreadyExists();
    error SessionNotFound();
    error SessionRevoked();
    error SessionExpired();
    error SessionNotYetValid();
    error InvalidSessionId();
    error InvalidOwnerSignature();
    error InvalidRailguardSignature();
    error InvalidSessionKey();
    error BatchNotAllowed();
    error DelegatecallRejected();
    error UnknownExecutionMode();
    error SelfCallRejected();
    error NativeEthRejected();
    error UnsupportedSelector();
    error WrongRecipient();
    error WrongTarget();
    error WrongToken();
    error ExceedsMaxPerTransfer();
    error ExceedsMaxTotalSpend();
    error ExecutionReplayed();
    error Unauthorized();
    error HookCallFailed();
    error InvalidAccount();
}
