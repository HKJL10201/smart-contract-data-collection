//SPDX-License-Identifier: MIT

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
import {MockNFT} from "src/MockERC721.sol";
import {DutchAuction} from "src/DutchAuction.sol";

/// @title DutchAuction.sol test contract
/// @author @0xValerius
/// @notice This contract tests the DutchAuction contract using the Forge Test framework.
contract DutchAuctionTest is Test {
    MockNFT nft;
    DutchAuction auction;

    address deployer = address(0x1);
    uint256 initialBalance = 1000;
    address actor2 = address(0x2);
    address actor3 = address(0x3);
    uint256 startPrice = 100;
    uint256 minPrice = 10;
    uint256 tokenId = 420;
    uint256 startAt = 20;
    uint256 duration = 100;
    uint256 endAt = startAt + duration;

    /// @notice Set up the test environment
    function setUp() public {
        // load address ether balances
        vm.deal(deployer, initialBalance);
        vm.deal(actor2, initialBalance);
        vm.deal(actor3, initialBalance);

        // deploy MockNFT
        nft = new MockNFT("MockNFT", "MOCK", deployer, tokenId);

        // deploy DutchAuction
        vm.prank(deployer);
        auction = new DutchAuction(duration, startAt, startPrice, minPrice, address(nft), tokenId);
    }

    /// @notice Test the deployment of the MockNFT contract
    function test_MockNFTDeploy() public {
        assertEq(nft.name(), "MockNFT");
        assertEq(nft.symbol(), "MOCK");
        assertEq(nft.balanceOf(deployer), 1);
        assertEq(nft.tokenURI(tokenId), "");
        assertEq(nft.ownerOf(tokenId), deployer);
    }

    /// @notice Test the deployment of the DutchhAuction contract
    function test_DutchAuctionDeployment() public {
        assertEq(auction.seller(), deployer);
        assertEq(auction.duration(), duration);
        assertEq(auction.startAt(), startAt);
        assertEq(auction.endAt(), endAt);
        assertEq(auction.startPrice(), startPrice);
        assertEq(auction.minPrice(), minPrice);
        assertEq(address(auction.nft()), address(nft));
        assertEq(auction.tokenId(), tokenId);
    }

    /// @notice Test the escrow process for the DutchAuction contract
    function test_DutchAuctionEscrow() public {
        assertEq(auction.isEscrowed(), false);
        vm.startPrank(deployer);
        nft.approve(address(auction), tokenId);
        nft.transferFrom(deployer, address(auction), tokenId);
        assertEq(auction.isEscrowed(), true);
        vm.stopPrank();
    }

    /// @notice Test the DutchAuction contract getPrice() function
    function test_getPrice() public {
        // check price before auction start
        vm.expectRevert("DutchAuction: auction has not started yet.");
        auction.getPrice();

        // send NFT to auction contract
        vm.startPrank(deployer);
        nft.approve(address(auction), tokenId);
        nft.transferFrom(deployer, address(auction), tokenId);
        vm.stopPrank();

        // check price at the beginning of the auction
        vm.startPrank(actor2);
        vm.warp(startAt); // block.timeamp = startAt
        assertEq(auction.getPrice(), 100); // price = startPrice

        // check price in the middle of the auction
        vm.warp(startAt + duration / 2);
        assertEq(auction.getPrice(), (startPrice + minPrice) / 2);

        // check price at the end of the auction
        vm.warp(endAt);
        assertEq(auction.getPrice(), minPrice);
    }

    /// @notice Test the DutchAuction contract bid() function
    function test_Bid() public {
        // send NFT to auction contract
        vm.startPrank(deployer);
        nft.approve(address(auction), tokenId);
        nft.transferFrom(deployer, address(auction), tokenId);
        assertEq(nft.ownerOf(tokenId), address(auction));
        vm.stopPrank();

        // check bid before auction start
        vm.expectRevert("DutchAuction: auction has not started yet.");
        auction.bid();

        // let the auction start
        vm.warp(startAt + duration / 3);

        // revert when seller tries to buy
        vm.startPrank(deployer);
        vm.expectRevert("DutchAuction: seller cannot bid.");
        auction.bid{value: 1000}();
        vm.stopPrank();

        // fetch price
        uint256 price = auction.getPrice();

        // revert on lower offer
        vm.startPrank(actor2);
        vm.expectRevert("DutchAuction: msg.value must be greater than or equal to current price.");
        auction.bid{value: price - 10}();
        vm.stopPrank();

        // successfull bid and refund ETH excess
        vm.startPrank(actor3);
        auction.bid{value: price + 10}();
        vm.stopPrank();
        assertEq(actor3.balance, initialBalance - price);
        assertEq(nft.ownerOf(tokenId), actor3);
        assertEq(deployer.balance, initialBalance + price);
        assertEq(address(auction).balance, 0);
        assertEq(auction.isEscrowed(), false);
    }

    /// @notice Test the DutchAuction contract noSale() function
    function test_noSale() public {
        // send NFT to auction contract
        vm.startPrank(deployer);
        nft.approve(address(auction), tokenId);
        nft.transferFrom(deployer, address(auction), tokenId);
        assertEq(nft.ownerOf(tokenId), address(auction));

        // check noSale before auction start
        vm.expectRevert("DutchAuction: auction has not ended yet.");
        auction.noSale();

        // let the auction start
        vm.warp(startAt + duration / 3);

        // check noSale when auction is active
        vm.expectRevert("DutchAuction: auction has not ended yet.");
        auction.noSale();
        vm.stopPrank();

        // let the auction end
        vm.warp(endAt + 1);

        // check noSale when auction is ended and user tries to call it
        vm.prank(actor2);
        vm.expectRevert("DutchAuction: only seller can call this function.");
        auction.noSale();

        // check noSale when auction is ended and seller calls it
        vm.startPrank(deployer);
        auction.noSale();
        vm.stopPrank();
        assertEq(nft.ownerOf(tokenId), deployer);
    }
}
