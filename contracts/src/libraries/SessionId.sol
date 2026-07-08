// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SessionTypes} from "./SessionTypes.sol";

/// @title SessionId
/// @notice Deterministic session identity derivation shared with off-chain systems.
library SessionId {
    function sessionConfigPhysicalHash(SessionTypes.SessionConfig memory config) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                config.sessionKey,
                config.token,
                config.allowedTarget,
                config.allowedRecipient,
                config.allowedSelector,
                config.maxPerTransfer,
                config.maxTotalSpend,
                config.validAfter,
                config.validUntil,
                config.allowBatch
            )
        );
    }

    function deriveSessionId(address adapter, address account, uint192 nonceKey, bytes32 physicalHash)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(block.chainid, adapter, account, nonceKey, physicalHash));
    }

    function deriveSessionIdFromConfig(address adapter, SessionTypes.SessionConfig memory config)
        internal
        view
        returns (bytes32)
    {
        bytes32 physical = sessionConfigPhysicalHash(config);
        return deriveSessionId(adapter, config.account, config.nonceKey, physical);
    }
}
