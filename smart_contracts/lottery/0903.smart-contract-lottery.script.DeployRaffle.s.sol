// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubcription, AddConsumer} from "../script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 keyHash,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address link,
            uint256 deployer
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            // we neet to create a new subscription
            CreateSubscription subscription = new CreateSubscription();
            subscriptionId = subscription.createSubscription(vrfCoordinator, deployer);

            // Fund the subscription
            FundSubcription fundSubscription = new FundSubcription();
            fundSubscription.fundSubscription(vrfCoordinator, subscriptionId, link, deployer);
        }

        vm.startBroadcast(deployer);
        Raffle raffle = new Raffle(entranceFee, interval, vrfCoordinator, keyHash, subscriptionId, callbackGasLimit);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), vrfCoordinator, subscriptionId, deployer);

        return (raffle, helperConfig);
    }
}
