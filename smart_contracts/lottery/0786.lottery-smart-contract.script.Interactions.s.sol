// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "@foundry-devops/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createVRFSubscription(
        address vrfCoordinator,
        uint256 deployerKey
    ) public returns (uint64) {
        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Your VRF subId is:", subId);
        console.log("Dont forget to add your VRF subId to HelperConfig.s.sol");
        return subId;
    }

    function createVRFSubscriptionUsingConfig() public returns (uint64) {
        // getting the VRF Coordinator
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , , , uint256 deployerKey) = helperConfig
            .activeNetworkConfig();

        return createVRFSubscription(vrfCoordinator, deployerKey);
    }

    function run() external returns (uint64) {
        return createVRFSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundVRFSubscription(
        address vrfCoordinator,
        uint64 subId,
        address link,
        uint256 deployerKey
    ) public {
        console.log("Funding subscription: ", subId);
        console.log("Using VRF Coordinator: ", vrfCoordinator);
        console.log("On chain id: ", block.chainid);

        if (block.chainid == 31337) {
            // fund using VRFCoordinatorV2Mock when using Anvil
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            // fund using LinkToken Mock
            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            uint64 subId,
            ,
            ,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        // fund
        fundVRFSubscription(vrfCoordinator, subId, link, deployerKey);
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(
        address vrfCoordinatorAddress,
        uint64 subId,
        address consumerContract,
        uint256 deployerKey
    ) public {
        console.log("Adding consumer contract: ", consumerContract);
        console.log("Using VRFCoordinator: ", vrfCoordinatorAddress);
        console.log("On ChainID: ", block.chainid);

        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinatorAddress).addConsumer(
            subId,
            consumerContract
        );
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address consumerContract) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinatorAddress,
            uint64 subId,
            ,
            ,
            ,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        addConsumer(
            vrfCoordinatorAddress,
            subId,
            consumerContract,
            deployerKey
        );
    }

    function run() external {
        address consumerContract = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(consumerContract);
    }
}
