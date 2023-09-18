// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/NounsTrade.sol";
import "./mock/NounsToken.sol";

contract NounsTradeTest is Test {
    NounsToken public nounsToken;
    NounsTrade public tradeContract;

    function setUp() public {
        address owner = address(0x2953c99fc4262350e0312132a92aA5bA1553249D);
        vm.prank(0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03);
        nounsToken = new NounsToken();
        tradeContract = new NounsTrade(owner, address(nounsToken));
    }

    function getInitHash() public pure returns (bytes32) {
        bytes memory bytecode = type(NounsTrade).creationCode;
        bytes memory initCode = abi.encodePacked(
            bytecode, abi.encode(0x2953c99fc4262350e0312132a92aA5bA1553249D, 0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03)
        );
        return keccak256(initCode);
    }

    function testInitHash() public {
        bytes32 initHash = getInitHash();
        emit log_bytes32(initHash);
    }

    function testSetAndGetOfferStatus() public {
        address testAddr = address(1);

        nounsToken.safeMint(testAddr);

        console.log(nounsToken.balanceOf(testAddr));

        assertFalse(tradeContract.getOpenForOfferStatus(0));

        vm.prank(testAddr);
        tradeContract.setOpenForOfferStatus(0, true);

        assertTrue(tradeContract.getOpenForOfferStatus(0));
    }

    function testFailCreateCounterOfferWithoutApprove() public {
        address ownerOne = address(1);
        address ownerTwo = address(2);

        nounsToken.safeMint(ownerOne); // tokenId 0
        nounsToken.safeMint(ownerTwo); // tokenId 1

        vm.prank(ownerOne);
        tradeContract.setOpenForOfferStatus(0, true);

        vm.prank(ownerTwo);
        tradeContract.createCounterOffer(0, 1);
    }

    function testCreateCounterOfferWithApprove() public {
        address ownerOne = address(1);
        address ownerTwo = address(2);

        nounsToken.safeMint(ownerOne); // tokenId 0
        nounsToken.safeMint(ownerTwo); // tokenId 1

        vm.prank(ownerOne);
        tradeContract.setOpenForOfferStatus(0, true);

        vm.startPrank(ownerTwo);
        nounsToken.approve(address(tradeContract), 1);
        tradeContract.createCounterOffer(0, 1);
        vm.stopPrank();
    }

    function testFailAcceptOfferWithoutApprove() public {
        address ownerOne = address(1);
        address ownerTwo = address(2);

        nounsToken.safeMint(ownerOne); // tokenId 0
        nounsToken.safeMint(ownerTwo); // tokenId 1

        vm.prank(ownerOne);
        tradeContract.setOpenForOfferStatus(0, true);

        assertTrue(tradeContract.getOpenForOfferStatus(0));

        vm.startPrank(ownerTwo);
        nounsToken.approve(address(tradeContract), 1);
        tradeContract.createCounterOffer(0, 1);
        vm.stopPrank();

        vm.prank(ownerOne);
        assertFalse(tradeContract.acceptOffer(0, 1));

        assertFalse(tradeContract.getOpenForOfferStatus(0));
    }

    function testAcceptOfferWithApprove() public {
        address ownerOne = address(1);
        address ownerTwo = address(2);

        nounsToken.safeMint(ownerOne); // tokenId 0
        nounsToken.safeMint(ownerTwo); // tokenId 1

        vm.prank(ownerOne);
        tradeContract.setOpenForOfferStatus(0, true);

        vm.startPrank(ownerTwo);
        nounsToken.approve(address(tradeContract), 1);
        tradeContract.createCounterOffer(0, 1);
        vm.stopPrank();

        assertTrue(tradeContract.getOpenForOfferStatus(0));

        vm.startPrank(ownerOne);
        nounsToken.approve(address(tradeContract), 0);
        assertTrue(tradeContract.acceptOffer(0, 1));
        vm.stopPrank();

        assertFalse(tradeContract.getOpenForOfferStatus(0));

        // verify owner are right
        assertEq(nounsToken.ownerOf(0), ownerTwo);
        assertEq(nounsToken.ownerOf(1), ownerOne);
    }

    function testContractIsPausable() public {
        tradeContract.setPauseStatus(true);

        vm.expectRevert("contract is paused");
        tradeContract.setOpenForOfferStatus(0, true);

        vm.expectRevert("contract is paused");
        tradeContract.acceptOffer(0, 1);

        vm.expectRevert("contract is paused");
        tradeContract.createCounterOffer(1, 0);
    }

    function testOnlyOwner() public {
        vm.prank(address(1));
        vm.expectRevert("only the owner is allowed to do this");
        tradeContract.setOwner(address(1));

        assertEq(tradeContract.owner(), address(this));

        tradeContract.setOwner(address(1));
        assertEq(tradeContract.owner(), address(1));

        vm.prank(address(1));
        tradeContract.setOwner(address(2));

        assertEq(tradeContract.owner(), address(2));
    }
}
