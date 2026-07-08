// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IRailguardSessionValidator
/// @notice ERC-4337 validation helper for session-key UserOperations.
interface IRailguardSessionValidator {
    function validateSessionKey(address account, uint192 nonceKey, bytes32 userOpHash, bytes calldata signature)
        external
        view
        returns (bool);
}
