// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    uint64 subscriptionId;

    function createSubscriptionUsingConfig() public returns (uint64) {
        // We will need the vrfCoordinator address to create a subscription
        HelperConfig helperConfig = new HelperConfig();

        (,, address vrfCoordinator,,,,,uint256 deployer) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator, deployer);
    }

    function createSubscription(address vrfCoordinator, uint256 deployer) public returns (uint64) {
        console.log("Creating subscription on chainId: ", block.chainid);
        if (block.chainid == 31337) {
            vm.startBroadcast(deployer);
            subscriptionId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
            vm.stopBroadcast();
            console.log("Your sub Id is ", subscriptionId);
            console.log("Subscription created on Anvil Chain");
            return subscriptionId;
        }
        vm.startBroadcast(deployer);
        subscriptionId = VRFCoordinatorV2Interface(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription Id is ", subscriptionId);
        console.log("Subscription created on chain", block.chainid);
        return subscriptionId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubcription is Script {
    uint96 constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public returns (bool) {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,, uint64 subscriptionId,, address link, uint256 deployer) = helperConfig.activeNetworkConfig();
        return fundSubscription(vrfCoordinator, subscriptionId, link, deployer);
    }

    function fundSubscription(address vrfCoordinator, uint64 subscriptionId, address link, uint256 deployer) public returns (bool) {
        console.log("Funding subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);

        bool isSuccess = false;
        if (block.chainid == 31337) {
            vm.startBroadcast(deployer);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            isSuccess = true;
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployer);
            isSuccess = LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }

        return isSuccess;
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(address raffle, address vrfCoordinator, uint64 subscriptionId, uint256 deployer) public {
        console.log("Adding consumer contract: ", raffle);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);

        if (block.chainid == 31337) {
            vm.startBroadcast(deployer);
            VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subscriptionId, raffle);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployer);
            VRFCoordinatorV2Interface(vrfCoordinator).addConsumer(subscriptionId, raffle);
            vm.stopBroadcast();
        }
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,, uint64 subscriptionId,,,uint256 deployer) = helperConfig.activeNetworkConfig();
        addConsumer(raffle, vrfCoordinator, subscriptionId, deployer);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffle);
    }
}
