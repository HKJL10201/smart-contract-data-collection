// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../src/Blind-Auction-Factory.sol";
import "../src/Blind-Auction.sol";
import "../src/W3BNFT.sol";
import "../src/IW3BNFT.sol";
import "../src/IBlindAuction.sol";

contract BlindAuctionTest is Test {
    BlindAuctionFactory public factory;
    W3BNFT public nftContract;

    function setUp() public {
        vm.startPrank(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        factory = new BlindAuctionFactory();
        nftContract = new W3BNFT("Web 3 Bridge", "W3B");
        nftContract.mint(1);
        vm.stopPrank();
    }

    function test_AuctionFactory() public {
        vm.prank(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        factory.createBlindAuction(3600 minutes);
    }


    function test_createAuction() public {
        vm.startPrank(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        address sampleAuction = factory.createBlindAuction(3600 minutes);
        IERC721(nftContract).approve(sampleAuction, 1);
        IBlindAuction(sampleAuction).createAuction(address(nftContract), 1);
        vm.stopPrank();
    }


    function test_cancelAuction() public{
        vm.startPrank(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        address sampleAuction = factory.createBlindAuction(3600);
        IERC721(nftContract).approve(sampleAuction, 1);
        IBlindAuction(sampleAuction).createAuction(address(nftContract), 1);
        IBlindAuction(sampleAuction).cancelAuction();
        vm.stopPrank();
    }


    function testFail_commitAfterCancelAuctionBeforeAuctionEnd() public{
        vm.startPrank(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        address sampleAuction = factory.createBlindAuction(3600);
        IERC721(nftContract).approve(sampleAuction, 1);
        IBlindAuction(sampleAuction).createAuction(address(nftContract), 1);
        IBlindAuction(sampleAuction).cancelAuction();
        IBlindAuction(sampleAuction).CommitBid(20, "money");
        vm.stopPrank();
    }


    function test_CancelIfNoBidorAddressZeroWinner() public{
        vm.startPrank(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        address sampleAuction = factory.createBlindAuction(3600);
        IERC721(nftContract).approve(sampleAuction, 1);
        IBlindAuction(sampleAuction).createAuction(address(nftContract), 1);
        vm.warp(block.timestamp + 3600 minutes);
        IBlindAuction(sampleAuction).getWinner();
        vm.stopPrank();
    }


    function testFail_withdrawAfterCancelAuctionAfterAuctionEnd() public{
        address sampleAuction = factory.createBlindAuction(3600);
        IERC721(nftContract).approve(sampleAuction, 1);
        IBlindAuction(sampleAuction).createAuction(address(nftContract), 1);
        IBlindAuction(sampleAuction).CommitBid(20, "money");
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        IBlindAuction(sampleAuction).CommitBid(10, "moni");
        vm.warp(block.timestamp + 3600 minutes);
        IBlindAuction(sampleAuction).RevealBid(20, "money");
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        IBlindAuction(sampleAuction).RevealBid(10, "moni");
        IBlindAuction(sampleAuction).getWinner();
        IBlindAuction(sampleAuction).cancelAuction();
        IBlindAuction(sampleAuction).withdrawFunds();
    }



     function test_FullAuction() public {
        vm.startPrank(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        address sampleAuction = factory.createBlindAuction(3600);
        IERC721(nftContract).approve(sampleAuction, 1);
        IBlindAuction(sampleAuction).createAuction(address(nftContract), 1);
        vm.stopPrank();
        IBlindAuction(sampleAuction).CommitBid(10 ether, "moneyman");
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        IBlindAuction(sampleAuction).CommitBid(20 ether, "moniman");
        vm.warp(block.timestamp + 3600 minutes);
        IBlindAuction(sampleAuction).RevealBid(10 ether, "moneyman");
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        IBlindAuction(sampleAuction).RevealBid(20 ether, "moniman");
        vm.prank(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        IBlindAuction(sampleAuction).getWinner();
        vm.deal(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 10000 ether);
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        IBlindAuction(sampleAuction).claimItem{value: 20 ether}();
        vm.prank(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        IBlindAuction(sampleAuction).withdrawFunds();
    }

}
