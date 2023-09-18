// SPDX-License-Identifier: MIT

/*

      .oooo.               oooooo     oooo           oooo                      o8o                       
     d8P'`Y8b               `888.     .8'            `888                      `"'                       
    888    888 oooo    ooo   `888.   .8'    .oooo.    888   .ooooo.  oooo d8b oooo  oooo  oooo   .oooo.o 
    888    888  `88b..8P'     `888. .8'    `P  )88b   888  d88' `88b `888""8P `888  `888  `888  d88(  "8 
    888    888    Y888'        `888.8'      .oP"888   888  888ooo888  888      888   888   888  `"Y88b.  
    `88b  d88'  .o8"'88b        `888'      d8(  888   888  888    .o  888      888   888   888  o.  )88b 
     `Y8bd8P'  o88'   888o       `8'       `Y888""8o o888o `Y8bod8P' d888b    o888o  `V88V"V8P' 8""888P' 

*/

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {MockNFT} from "../src/MockERC721.sol";
import {EnglishAuction} from "../src/EnglishAuction.sol";

/// @title EnglishAuction.sol test contract
/// @author @0xValerius
/// @notice This contract tests the EnglishAuction contract using the Forge Test framework.
contract EnglishAuctionTest is Test {
    MockNFT nft;
    EnglishAuction auction;

    address deployer = address(0x1);
    uint256 initialBalance = 1000;
    address actor2 = address(0x2);
    address actor3 = address(0x3);
    address actor4 = address(0x4);
    uint256 duration = 10000;
    uint256 startAt = 20;
    uint256 endAt = startAt + duration;
    uint256 reservePrice = 100;
    uint256 tokenId = 420;

    /// @notice Set up the test environment
    function setUp() public {
        // load address ether balances
        vm.deal(deployer, initialBalance);
        vm.deal(actor2, initialBalance);
        vm.deal(actor3, initialBalance);
        vm.deal(actor4, initialBalance);

        // deploy MockNFT
        nft = new MockNFT("MockNFT", "MOCK", deployer, tokenId);

        // deploy EnglishAuction
        vm.prank(deployer);
        auction = new EnglishAuction(duration, startAt, reservePrice, address(nft), tokenId);
    }

    /// @notice Test the deployment of the MockNFT contract
    function test_MockNFTDeploy() public {
        assertEq(nft.name(), "MockNFT");
        assertEq(nft.symbol(), "MOCK");
        assertEq(nft.balanceOf(deployer), 1);
        assertEq(nft.tokenURI(tokenId), "");
        assertEq(nft.ownerOf(tokenId), deployer);
    }

    /// @notice Test the deployment of the EnglishAuction contract
    function test_EnglishAuctionDeployment() public {
        assertEq(auction.seller(), deployer);
        assertEq(auction.duration(), duration);
        assertEq(auction.startAt(), startAt);
        assertEq(auction.endAt(), endAt);
        assertEq(auction.reservePrice(), reservePrice);
        assertEq(address(auction.nft()), address(nft));
        assertEq(auction.tokenId(), tokenId);
    }

    /// @notice Test the escrow process for the EnglishAuction contract
    function test_EnglishAuctionEscrow() public {
        assertEq(auction.isEscrowed(), false);
        vm.startPrank(deployer);
        nft.approve(address(auction), tokenId);
        nft.transferFrom(deployer, address(auction), tokenId);
        assertEq(auction.isEscrowed(), true);
        vm.stopPrank();
    }

    /// @notice Test a successful auction process
    function test_successFullAuction() public {
        vm.startPrank(deployer);
        nft.approve(address(auction), tokenId);
        nft.transferFrom(deployer, address(auction), tokenId);
        vm.stopPrank();

        // let the auction start
        vm.warp(startAt + duration / 2);

        // actor2 bids under reserve price - revert
        vm.startPrank(actor2);
        vm.expectRevert("EnglishAuction: bid must be greater than reserve price.");
        auction.bid{value: reservePrice / 2}();
        assertEq(auction.highestBid(), 0);
        assertEq(auction.highestBidder(), address(0));

        // actor2 bids over reserve price - success
        auction.bid{value: reservePrice * 2}();
        assertEq(auction.highestBid(), reservePrice * 2);
        assertEq(auction.highestBidder(), actor2);
        assertEq(actor2.balance, initialBalance - reservePrice * 2);
        assertEq(address(auction).balance, reservePrice * 2);

        // highest bidder (actor2) withdraws - revert
        vm.expectRevert("EnglishAuction: highest bidder cannot withdraw.");
        auction.withdraw();
        vm.stopPrank();

        // actor3 bids under highest bid - revert
        vm.startPrank(actor3);
        vm.expectRevert("EnglishAuction: bid must be greater than highest bid.");
        auction.bid{value: reservePrice * 3 / 2}();

        // actor3 bids over highest bid - success
        auction.bid{value: reservePrice * 3}();
        assertEq(auction.highestBid(), reservePrice * 3);
        assertEq(auction.highestBidder(), actor3);
        assertEq(actor3.balance, initialBalance - reservePrice * 3);
        assertEq(address(auction).balance, reservePrice * 3 + reservePrice * 2);

        // highest bidder (actor3) withdraws - revert
        vm.expectRevert("EnglishAuction: highest bidder cannot withdraw.");
        auction.withdraw();
        vm.stopPrank();

        // previous highest bidder (actor2) withdraws - success
        vm.prank(actor2);
        auction.withdraw();
        assertEq(actor2.balance, initialBalance);
        assertEq(address(auction).balance, reservePrice * 3);

        // auctions ends
        vm.warp(endAt + 1);

        // any user call claim()
        vm.prank(actor4);
        auction.claim();
        assertEq(auction.isEscrowed(), false);
        assertEq(nft.ownerOf(tokenId), actor3);
        assertEq(address(auction).balance, 0);
        assertEq(deployer.balance, initialBalance + reservePrice * 3);
    }

    /// @notice Test an empty auction process (no bids placed)
    function test_emptyAuction() public {
        vm.startPrank(deployer);
        nft.approve(address(auction), tokenId);
        nft.transferFrom(deployer, address(auction), tokenId);
        vm.stopPrank();

        // let the auction start
        vm.warp(startAt + duration / 2);

        // auctions ends
        vm.warp(endAt + 1);

        // any user call claim()
        vm.prank(actor4);
        auction.claim();
        assertEq(auction.isEscrowed(), false);
        assertEq(nft.ownerOf(tokenId), deployer);
        assertEq(address(auction).balance, 0);
        assertEq(deployer.balance, initialBalance);
    }
}
