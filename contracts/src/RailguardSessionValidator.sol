// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IRailguardAccountAdapter} from "./interfaces/IRailguardAccountAdapter.sol";
import {IRailguardSessionValidator} from "./interfaces/IRailguardSessionValidator.sol";
import {RailguardErrors} from "./libraries/RailguardErrors.sol";
import {SessionTypes} from "./libraries/SessionTypes.sol";

/// @title RailguardSessionValidator
/// @notice Validation-safe session key checks for ERC-4337 nonce lanes.
contract RailguardSessionValidator is IRailguardSessionValidator {
    address public immutable adapter;

    constructor(address adapter_) {
        if (adapter_ == address(0)) revert RailguardErrors.ZeroAddress();
        adapter = adapter_;
    }

    function validateSessionKey(address account, uint192 nonceKey, bytes32 userOpHash, bytes calldata signature)
        external
        view
        returns (bool)
    {
        SessionTypes.SessionConfig memory session = IRailguardAccountAdapter(adapter).getSession(account, nonceKey);
        if (session.account == address(0)) return false;
        if (session.revoked) return false;
        if (block.timestamp < session.validAfter) return false;
        if (block.timestamp > session.validUntil) return false;

        (address recovered, ECDSA.RecoverError err, ) = ECDSA.tryRecover(userOpHash, signature);
        if (err != ECDSA.RecoverError.NoError) return false;
        return recovered == session.sessionKey;
    }
}
