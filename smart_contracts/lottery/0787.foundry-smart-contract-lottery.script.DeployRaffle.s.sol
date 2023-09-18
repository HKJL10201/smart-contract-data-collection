//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (uint256 entranceFee,
        uint256 interval,
        address coordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        address link,
        uint256 deployerKey) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            // we are going to need to create a subscription
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(coordinator, deployerKey);
        }

        //fund subscription
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(coordinator, subscriptionId, link);

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            coordinator,
            keyHash,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), coordinator, subscriptionId, deployerKey);

        return (raffle, helperConfig);
    }
}