//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script{

    function createSubscriptionUsingConfig() public returns(uint64) {
        HelperConfig helperConfig = new HelperConfig();
         ( ,
         ,
        address coordinator,
         ,
         ,
         ,
         address link,
         uint deployerKey
         ) = helperConfig.activeNetworkConfig();
         return createSubscription(coordinator,deployerKey);
    }

    function createSubscription (address coordinator,uint deployerKey) public returns(uint64){
        console.log("Creating subscription on chain id: %s", block.chainid);
        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(coordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription id: %s", subId);
        console.log("Please update subscription id in HelperConfig.s.sol");
        return subId;
    }

    function run() external returns(uint64) {
        return createSubscriptionUsingConfig();
    }
    
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 1 ether;

    function fundSubscriptionUsingConfig() public {
         HelperConfig helperConfig = new HelperConfig();
         ( ,
         ,
        address coordinator,
         ,
         uint64 subscriptionId
         ,
         ,
         address link,

         ) = helperConfig.activeNetworkConfig();
         
    }

    function fundSubscription(address coordinator, uint64 subscriptionId, address link) public {
        console.log("Funding subscription on chain id: %s", block.chainid);
        if(block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(coordinator).fundSubscription(subscriptionId,FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(coordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();     
        }
        
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {

    function addConsumer(address raffle, address coordinator, uint64 subscriptionId, uint256 deployerKey) public {
        console.log("Adding consumer on chain id: %s", block.chainid);
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(coordinator).addConsumer(subscriptionId, raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig(); 
        ( ,
         ,
        address coordinator,
         ,
         uint64 subscriptionId
         ,
         ,
         address link,
         uint256 deployerKey
         ) = helperConfig.activeNetworkConfig();
         addConsumer(raffle, coordinator, subscriptionId, deployerKey);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }  
}