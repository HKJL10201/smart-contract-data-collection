// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { DeadjiraAuction } from "../src/Deadjira.sol";

contract DeadjiraTest is PRBTest, StdCheats {
    DeadjiraAuction deadjiraAuction;

    address public constant DEPLOYER = address(0xCd494517879f83e7c168140Dad89ED0EFED0231E);

    struct Purchase {
        address minted;
        uint256 value;
        uint256 id;
    }

    function setUp() public {
        vm.prank(DEPLOYER);
        deadjiraAuction = new DeadjiraAuction();
    }

    function testStartAuction() public {
        vm.prank(DEPLOYER);
        deadjiraAuction.startAuction();
        assertEq(deadjiraAuction.startTime(), block.timestamp);
    }

    function testCalculateStartPrice() public {
        vm.prank(DEPLOYER);
        deadjiraAuction.startAuction();
        assertEq(deadjiraAuction.calculatePrice(), 3.33 ether);
    }

    function testCalculatePrice() public {
        vm.prank(DEPLOYER);
        deadjiraAuction.startAuction();
        vm.warp(block.timestamp + 213 seconds);
        assertEq(deadjiraAuction.calculatePrice(), 3.22 ether);
    }

    function testMinimumPrice() public {
        vm.prank(DEPLOYER);
        deadjiraAuction.startAuction();
        vm.warp(block.timestamp + (213 seconds * 1000));
        assertEq(deadjiraAuction.calculatePrice(), 1.11 ether);
    }

    function testPurchase() public {
        vm.prank(DEPLOYER);
        deadjiraAuction.startAuction();
        deadjiraAuction.purchaseAuction{ value: 3.33 ether }("btcAddress", "discordID");
        assertEq(deadjiraAuction.buyers(0), address(this));
        assertEq(deadjiraAuction.purchased(deadjiraAuction.buyers(0)), 3.33 ether);
    }

    function test_IncorrectValue_Purchase() public {
        vm.prank(DEPLOYER);
        deadjiraAuction.startAuction();
        vm.expectRevert();
        deadjiraAuction.purchaseAuction{ value: 3.22 ether }("btcAddress", "discordID");
    }

    function test_AlreadyPurchased_Purchase() public {
        vm.prank(DEPLOYER);
        deadjiraAuction.startAuction();
        deadjiraAuction.purchaseAuction{ value: 3.33 ether }("btcAddress", "discordID");
        vm.expectRevert();
        deadjiraAuction.purchaseAuction{ value: 3.33 ether }("btcAddress", "discordID");
    }

    function test_togglePause() public {
        vm.prank(DEPLOYER);
        deadjiraAuction.startAuction();
        assertEq(deadjiraAuction.paused(), false);
        vm.prank(DEPLOYER);
        deadjiraAuction.togglePause();
        assertEq(deadjiraAuction.paused(), true);
    }

    function test_refund() public {
        vm.prank(DEPLOYER);
        vm.deal(DEPLOYER, 100 ether);
        deadjiraAuction.startAuction();
        vm.prank(DEPLOYER);
        deadjiraAuction.purchaseAuction{ value: 3.33 ether }("btcAddress", "discordID");
        uint256 startingBalance = DEPLOYER.balance;
        uint256 refundAmount = 3.33 ether - 1.11 ether;
        vm.prank(DEPLOYER);
        deadjiraAuction.togglePause();
        vm.prank(DEPLOYER);
        deadjiraAuction.refund(1.11 ether);
        assertEq(DEPLOYER.balance, startingBalance + refundAmount);
    }

    function test_withdraw() public {
        vm.prank(DEPLOYER);
        deadjiraAuction.setWithdrawAddress(DEPLOYER);
        vm.prank(DEPLOYER);
        vm.deal(DEPLOYER, 100 ether);
        deadjiraAuction.startAuction();
        vm.prank(DEPLOYER);
        deadjiraAuction.purchaseAuction{ value: 3.33 ether }("btcAddress", "discordID");
        uint256 startingBalance = DEPLOYER.balance;
        vm.prank(DEPLOYER);
        deadjiraAuction.togglePause();
        vm.prank(DEPLOYER);
        deadjiraAuction.withdraw();
        assertEq(DEPLOYER.balance, startingBalance + 3.33 ether);
    }

    function test_MaxSupply_Purchase() public {
        vm.prank(DEPLOYER);
        deadjiraAuction.startAuction();
        for (uint256 i = 0; i < 50; i++) {
            address user = vm.addr(i + 1);
            vm.prank(user);
            vm.deal(user, 100 ether);
            deadjiraAuction.purchaseAuction{ value: 3.33 ether }("btcAddress", "discordID");
        }
        vm.expectRevert();
        deadjiraAuction.purchaseAuction{ value: 3.33 ether }("btcAddress", "discordID");
    }

    function test_StartAlreadyStarted_startAuction() public {
        vm.prank(DEPLOYER);
        deadjiraAuction.startAuction();
        vm.prank(DEPLOYER);
        vm.expectRevert();
        deadjiraAuction.startAuction();
    }

    function test_FinalPriceInvalid_refund() public {
        vm.prank(DEPLOYER);
        vm.deal(DEPLOYER, 100 ether);
        deadjiraAuction.startAuction();
        vm.prank(DEPLOYER);
        deadjiraAuction.purchaseAuction{ value: 3.33 ether }("btcAddress", "discordID");
        vm.prank(DEPLOYER);
        deadjiraAuction.togglePause();
        vm.prank(DEPLOYER);
        vm.expectRevert();
        deadjiraAuction.refund(1.1 ether);
    }

    function test_RefundNoRefund_refund() public {
        vm.prank(DEPLOYER);
        vm.deal(DEPLOYER, 100 ether);
        deadjiraAuction.startAuction();
        vm.prank(DEPLOYER);
        deadjiraAuction.purchaseAuction{ value: 3.33 ether }("btcAddress", "discordID");
        uint256 startingValue = DEPLOYER.balance;
        vm.prank(DEPLOYER);
        deadjiraAuction.togglePause();
        vm.prank(DEPLOYER);
        deadjiraAuction.refund(3.33 ether);
        uint256 endingValue = DEPLOYER.balance;
        assertEq(endingValue, startingValue);
    }

    function test_AuctionPurchaseEmit_purchaseAuction() public {
        vm.prank(DEPLOYER);
        vm.deal(DEPLOYER, 100 ether);
        deadjiraAuction.startAuction();
        vm.prank(DEPLOYER);
        deadjiraAuction.purchaseAuction{ value: 3.33 ether }("btcAddress", "discordID");
    }

    function test_getTotalPurchased() public {
        assertEq(deadjiraAuction.getTotalPurchased(), 0);
        vm.prank(DEPLOYER);
        deadjiraAuction.startAuction();
        vm.prank(DEPLOYER);
        vm.deal(DEPLOYER, 100 ether);
        deadjiraAuction.purchaseAuction{ value: 3.33 ether }("btcAddress", "discordID");
        uint256 totalPurchased = deadjiraAuction.getTotalPurchased();
        assertEq(totalPurchased, 1);
    }

    function test_getUserPurchaseData() public {
        vm.prank(DEPLOYER);
        deadjiraAuction.startAuction();
        deadjiraAuction.purchaseAuction{ value: 3.33 ether }("btcAddress", "discordID");
        uint256 value = deadjiraAuction.getUserPurchaseData(address(this));
        assertEq(value, 3.33 ether);
    }
}
