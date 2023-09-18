// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinatorV2,
            uint256 entranceFee,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            uint256 interval,
            address link,
            uint256 deployerkey
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinatorV2,
                deployerkey
            );

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinatorV2,
                subscriptionId,
                link,
                deployerkey
            );
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            vrfCoordinatorV2,
            entranceFee,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            interval
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            vrfCoordinatorV2,
            subscriptionId,
            deployerkey
        );
        return (raffle, helperConfig);
    }
}
