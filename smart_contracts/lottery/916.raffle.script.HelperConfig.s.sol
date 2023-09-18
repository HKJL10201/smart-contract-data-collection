// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }

    NetworkConfig public activeNetworkConfig;
    constructor() {
        if(block.chainid == 11155111) {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        } else {
            activeNetworkConfig = getSepoliaEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            entranceFee : 0.01 ether,
            interval : 30,
            vrfCoordinator : 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
            gasLane : 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef,
            subscriptionId : 0,
            callbackGasLimit : 500000
        });
    }

    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory) {
        if(activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        uint96 baseFee = 0.25 ether;    // .25 LINK
        uint96 gasPriceLink = 1e9;  // 1 gwei LINK

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
        vm.stopBroadcast();

        return NetworkConfig({
            entranceFee : 0.01 ether,
            interval : 30,
            vrfCoordinator : address(vrfCoordinatorV2Mock),
            gasLane : 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef,
            subscriptionId : 0,
            callbackGasLimit : 500000
        });
    }
}