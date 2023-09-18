// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {MockNFT} from "src/MockERC721.sol";

contract MockNFTTest is Test {
    MockNFT nft;

    address deployer = address(0x1);
    address actor2 = address(0x2);
    address actor3 = address(0x3);
    uint256 tokenId = 420;

    function setUp() public {
        // load address ether balances
        vm.deal(deployer, 1000);
        vm.deal(actor2, 1000);
        vm.deal(actor3, 1000);

        // deploy MockNFT
        nft = new MockNFT("MockNFT", "MOCK", actor2, tokenId);
    }

    // Test the deployment of the MockNFT contract.
    function test_MockNFTDeploy() public {
        assertEq(nft.name(), "MockNFT");
        assertEq(nft.symbol(), "MOCK");
        assertEq(nft.balanceOf(actor2), 1);
        assertEq(nft.tokenURI(tokenId), "");
        assertEq(nft.ownerOf(tokenId), actor2);
    }

    // Test MockNFT owner called transferFrom() function.
    function test_MockNFTTransfer() public {
        vm.prank(actor2);
        nft.transferFrom(actor2, actor3, tokenId);
        assertEq(nft.balanceOf(actor2), 0);
        assertEq(nft.balanceOf(actor3), 1);
        assertEq(nft.ownerOf(tokenId), actor3);
    }

    // Test MockNFT spender called transferFrom() function.
    function test_MockNFTTransferFrom() public {
        vm.prank(actor2);
        nft.approve(deployer, tokenId);
        vm.prank(deployer);
        nft.transferFrom(actor2, actor3, tokenId);
        assertEq(nft.balanceOf(actor2), 0);
        assertEq(nft.balanceOf(actor3), 1);
        assertEq(nft.ownerOf(tokenId), actor3);
    }
}
