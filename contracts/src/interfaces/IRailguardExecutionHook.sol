// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SessionTypes} from "../libraries/SessionTypes.sol";

/// @title IRailguardExecutionHook
/// @notice Execution-phase safety hook invoked by RailguardAccountAdapter.
interface IRailguardExecutionHook {
    function preCheck(address account, uint192 nonceKey, bytes32 mode, bytes calldata executionCalldata)
        external
        returns (bytes memory hookData);

    function postCheck(bytes calldata hookData) external;

    function sessionSpend(address account, bytes32 sessionId) external view returns (uint256);

    function executionDigest(
        address account,
        bytes32 sessionId,
        uint192 nonceKey,
        bytes32 mode,
        bytes calldata executionCalldata
    ) external view returns (bytes32);
}
