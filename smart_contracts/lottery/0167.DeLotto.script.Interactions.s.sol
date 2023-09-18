// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// import {Script, console} from "forge-std/Script.sol";
// import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
// import {HelperConfig} from "./HelperConfig.s.sol";
// import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

// contract AddConsumer is Script {
//     function addConsumer(
//         address lottery,
//         address vrfCoordinator,
//         uint64 subId
//     ) public {
//         console.log("Adding consumer contract: ", lottery);
//         console.log("Using vrfCoordinator: ", vrfCoordinator);
//         console.log("On ChainID: ", block.chainid);
//         vm.startBroadcast();
//         VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, lottery);
//         vm.stopBroadcast();
//     }

//     function addConsumerUsingConfig(address lottery) public {
//         HelperConfig helperConfig = new HelperConfig();
//         (, address vrfCoordinatorV2, , uint64 subId, ) = helperConfig
//             .activeNetworkConfig();
//         addConsumer(lottery, vrfCoordinatorV2, subId);
//     }

//     function run() external {
//         address lottery = DevOpsTools.get_most_recent_deployment(
//             "Lottery",
//             block.chainid
//         );
//         addConsumerUsingConfig(lottery);
//     }
// }
