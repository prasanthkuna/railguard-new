// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SessionTypes} from "./SessionTypes.sol";
import {RailguardErrors} from "./RailguardErrors.sol";

/// @title ExecutionDecoder
/// @notice ERC-7579-style execution decoding for Railguard v1.
library ExecutionDecoder {
    using ExecutionDecoder for SessionTypes.Execution;

    function decodeSingle(bytes calldata executionCalldata)
        internal
        pure
        returns (address target, uint256 value, bytes memory callData)
    {
        if (executionCalldata.length < 52) revert RailguardErrors.UnknownExecutionMode();
        target = address(bytes20(executionCalldata[0:20]));
        value = uint256(bytes32(executionCalldata[20:52]));
        callData = executionCalldata[52:];
    }

    function decodeBatch(bytes calldata executionCalldata)
        internal
        pure
        returns (SessionTypes.Execution[] memory executions)
    {
        executions = abi.decode(executionCalldata, (SessionTypes.Execution[]));
    }

    function encodeSingle(address target, uint256 value, bytes memory callData) internal pure returns (bytes memory) {
        return abi.encodePacked(target, value, callData);
    }

    function encodeBatch(SessionTypes.Execution[] memory executions) internal pure returns (bytes memory) {
        return abi.encode(executions);
    }
}
