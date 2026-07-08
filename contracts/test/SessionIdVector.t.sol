// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {SessionId} from "../src/libraries/SessionId.sol";
import {SessionTypes} from "../src/libraries/SessionTypes.sol";

/// @notice Fixed cross-language sessionId vector. Keep in sync with Go/TS differential tests.
contract SessionIdVectorTest is Test {
    address internal constant ADAPTER = address(0xc0);
    address internal constant ACCOUNT = address(0x1);
    address internal constant SESSION_KEY = address(0x2);

    function test_export_session_id_vector() public {
        vm.chainId(84532);
        SessionTypes.SessionConfig memory config = SessionTypes.SessionConfig({
            sessionId: bytes32(0),
            policyHash: bytes32(uint256(0x11)),
            account: ACCOUNT,
            sessionKey: SESSION_KEY,
            token: address(0xaa),
            allowedTarget: address(0xaa),
            allowedRecipient: address(0xb01),
            allowedSelector: SessionTypes.TRANSFER_SELECTOR,
            nonceKey: 12345,
            maxPerTransfer: 100_000_000,
            maxTotalSpend: 500_000_000,
            validAfter: 1,
            validUntil: 9_999_999_999,
            allowBatch: false,
            revoked: false
        });

        bytes32 physical = SessionId.sessionConfigPhysicalHash(config);
        console2.logBytes32(physical);
        bytes32 id = SessionId.deriveSessionId(ADAPTER, ACCOUNT, 12345, physical);
        console2.logBytes32(id);
        assertEq(physical, 0xce82cb832c840475ee7585ea677c2b289397058e10dcc9f4478e17415cdffb86);
        assertEq(id, 0x52a14e7814be7dbf606ee36eb57bef03d9d9e50b72bd13097f14eb123d26b936);
    }
}
