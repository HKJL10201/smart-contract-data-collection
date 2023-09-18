// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        AddConsumer addConsumer = new AddConsumer();
        (
            uint256 raffleEntryFee,
            uint256 interval,
            address vrfCoordinatorV2,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinatorV2, deployerKey);
        }

        // Fund it
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(vrfCoordinatorV2, subscriptionId, link, deployerKey);

        vm.startBroadcast(deployerKey);
        Raffle raffle = new Raffle(
             raffleEntryFee,
             interval,
             vrfCoordinatorV2,
             gasLane,
             subscriptionId,
             callbackGasLimit             
            );

        vm.stopBroadcast();

        // We already have a broadcast in here
        addConsumer.addConsumer(address(raffle), vrfCoordinatorV2, subscriptionId, deployerKey);

        return (raffle, helperConfig);
    }
}
