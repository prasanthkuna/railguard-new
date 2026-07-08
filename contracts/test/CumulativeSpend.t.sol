// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RailguardTestBase} from "./RailguardTestBase.sol";
import {ExecutionDecoder} from "../src/libraries/ExecutionDecoder.sol";
import {RailguardErrors} from "../src/libraries/RailguardErrors.sol";
import {SessionTypes} from "../src/libraries/SessionTypes.sol";

contract BatchCumulativeSpendTest is RailguardTestBase {
    function test_batch_aggregate_exceeding_session_cap_reverts() public {
        _register(true);
        SessionTypes.Execution[] memory leaves = new SessionTypes.Execution[](6);
        for (uint256 i = 0; i < 6; i++) {
            leaves[i] = SessionTypes.Execution(address(usdc), 0, _transferCalldata(recipient, 90e6));
        }
        bytes memory execution = ExecutionDecoder.encodeBatch(leaves);
        vm.prank(sessionKey);
        vm.expectRevert(RailguardErrors.ExceedsMaxTotalSpend.selector);
        adapter.executeWithSession(NONCE_KEY, SessionTypes.CALLTYPE_BATCH, execution);
    }
}
