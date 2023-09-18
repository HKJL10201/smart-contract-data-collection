// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

// import {AddConsumer} from "script/Interactions.s.sol";

contract DeployLottery is Script {
    function run() external returns (Lottery, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // AddConsumer addConsumer = new AddConsumer();

        (
            uint256 entryFee,
            address vrfCoordinatorV2,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit
        ) = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        Lottery lottery = new Lottery(
            subscriptionId,
            gasLane,
            entryFee,
            callbackGasLimit,
            vrfCoordinatorV2
        );
        vm.stopBroadcast();

        // addConsumer.addConsumer(
        //     address(lottery),
        //     vrfCoordinatorV2,
        //     subscriptionId
        // );

        return (lottery, helperConfig);
    }
}
