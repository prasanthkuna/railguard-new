// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SessionTypes} from "../libraries/SessionTypes.sol";

/// @title IRailguardAccountAdapter
/// @notice V1 Railguard smart account adapter.
interface IRailguardAccountAdapter {
    function registerSession(
        SessionTypes.SessionConfig calldata config,
        bytes calldata ownerSig,
        bytes calldata railguardSig
    ) external;

    function revokeSession(uint192 nonceKey) external;

    function executeWithSession(uint192 nonceKey, bytes32 mode, bytes calldata executionCalldata) external;

    function getSession(address account, uint192 nonceKey) external view returns (SessionTypes.SessionConfig memory);
}
