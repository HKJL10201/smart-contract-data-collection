// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";

contract InteractionsUnitTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;
    uint256 public subscriptionId;

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testCreateVRFSubscriptionWhenRunningOnLocalChain()
        public
        skipFork
    {
        CreateSubscription createSubscription = new CreateSubscription();
        subscriptionId = createSubscription.run();
        assert(subscriptionId > 0);
    }
}
