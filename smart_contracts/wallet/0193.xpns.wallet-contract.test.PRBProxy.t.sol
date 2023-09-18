pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {PRBProxy} from "../src/PRBProxy.sol";
import {Ticket} from "../src/Ticket.sol";

contract PRBProxyTest is Test {

    PRBProxy pRBProxy;
    Ticket ticket;

    uint160 addressCounter;

    address ownerAddress;

    function setUp() public {
        addressCounter = 1;
        address address1 = address(addressCounter);
        vm.deal(address1, 100 ether);

        vm.prank(address1);
        pRBProxy = new PRBProxy();
        ticket = new Ticket();

        ownerAddress = address1;

        vm.deal(address(pRBProxy), 100 ether);
    }

    function test_owner_token() public {
        assertEq(pRBProxy.ownerOf(0), ownerAddress);
    }

    function test_mint_pass() public {
        addressCounter = addressCounter + 1;
        address address1 = address(addressCounter);
        vm.deal(address1, 100 ether);

        uint256 limit = 100;
        vm.prank(ownerAddress);
        uint256 tokenId = pRBProxy.mintSpendooorPass(address1, limit);
        assertEq(pRBProxy.limitOf(tokenId), limit);
        assertEq(pRBProxy.balanceOf(address1), 1);
    }

    function test_mint_only_owner() public {
        addressCounter = addressCounter + 1;
        address address1 = address(addressCounter);
        vm.deal(address1, 100 ether);

        uint256 limit = 100;
        vm.prank(address1);
        vm.expectRevert();
        pRBProxy.mintSpendooorPass(address1, limit);
    }

    function test_change_limit() public {
        addressCounter = addressCounter + 1;
        address address1 = address(addressCounter);
        vm.deal(address1, 100 ether);

        uint256 limit1 = 100;
        uint256 limit2 = 200;
        vm.prank(ownerAddress);
        uint256 tokenId = pRBProxy.mintSpendooorPass(address1, limit1);
        vm.prank(ownerAddress);
        pRBProxy.setLimit(tokenId, limit2);
        assertEq(pRBProxy.limitOf(tokenId), limit2);
    }

    function test_change_limit_only_owner() public {
        addressCounter = addressCounter + 1;
        address address1 = address(addressCounter);
        vm.deal(address1, 100 ether);

        uint256 limit1 = 100;
        uint256 limit2 = 200;
        vm.prank(ownerAddress);
        uint256 tokenId = pRBProxy.mintSpendooorPass(address1, limit1);
        vm.prank(address1);
        vm.expectRevert();
        pRBProxy.setLimit(tokenId, limit2);
    }

    function test_only_mint_one_pass() public {
        addressCounter = addressCounter + 1;
        address address1 = address(addressCounter);
        vm.deal(address1, 100 ether);

        uint256 limit = 100;
        vm.prank(ownerAddress);
        pRBProxy.mintSpendooorPass(address1, limit);
        vm.prank(ownerAddress);
        vm.expectRevert();
        pRBProxy.mintSpendooorPass(address1, limit);
    }

    function test_mint_and_transfer() public {
        addressCounter = addressCounter + 1;
        address address1 = address(addressCounter);
        vm.deal(address1, 100 ether);

        addressCounter = addressCounter + 1;
        address address2 = address(addressCounter);
        vm.deal(address2, 100 ether);

        uint256 limit = 100;
        vm.prank(ownerAddress);
        uint256 tokenId = pRBProxy.mintSpendooorPass(address1, limit);
        vm.prank(address1);
        pRBProxy.safeTransferFrom(address1, address2, tokenId);
        assertEq(pRBProxy.balanceOf(address1), 0);
        assertEq(pRBProxy.balanceOf(address2), 1);
    }

    function test_mint_no_second_transfer() public {
        addressCounter = addressCounter + 1;
        address address1 = address(addressCounter);
        vm.deal(address1, 100 ether);
        addressCounter = addressCounter + 1;
        address address2 = address(addressCounter);
        vm.deal(address2, 100 ether);

        uint256 limit = 100;
        vm.prank(ownerAddress);
        pRBProxy.mintSpendooorPass(address1, limit);
        vm.prank(ownerAddress);
        uint256 tokenId = pRBProxy.mintSpendooorPass(address2, limit);
        vm.prank(address2);
        vm.expectRevert();
        pRBProxy.safeTransferFrom(address2, address1, tokenId);
    }

    function test_exec() public {
        addressCounter = addressCounter + 1;
        address address1 = address(addressCounter);
        vm.deal(address1, 100 ether);

        uint256 limit = 0.1 ether;

        assertEq(ticket.balanceOf(address1), 0);

        vm.prank(ownerAddress);
        pRBProxy.mintSpendooorPass(address1, limit);

        bytes memory transferPayload = abi.encodeWithSignature("mint(address)", address1);
        vm.prank(address1);
        pRBProxy.execute(address(ticket), 0.1 ether, transferPayload);

        assertEq(ticket.balanceOf(address1), 1);
    }

    function test_no_exec_when_no_pass() public {
        addressCounter = addressCounter + 1;
        address address1 = address(addressCounter);
        vm.deal(address1, 100 ether);

        bytes memory transferPayload = abi.encodeWithSignature("mint(address)", address1);
        vm.prank(address1);
        vm.expectRevert();
        pRBProxy.execute(address(ticket), 0.1 ether, transferPayload);
    }

    function test_no_exec_when_no_spendable_left_one_txs() public {
        addressCounter = addressCounter + 1;
        address address1 = address(addressCounter);
        vm.deal(address1, 100 ether);

        uint256 limit = 100;

        vm.prank(ownerAddress);
        pRBProxy.mintSpendooorPass(address1, limit);

        bytes memory transferPayload = abi.encodeWithSignature("mint(address)", address1);
        vm.prank(address1);
        vm.expectRevert();
        pRBProxy.execute(address(ticket), 0.1 ether, transferPayload);
    }

    function test_no_exec_when_no_spendable_left_two_txs() public {
        addressCounter = addressCounter + 1;
        address address1 = address(addressCounter);
        vm.deal(address1, 100 ether);

        uint256 limit = 0.15 ether;

        vm.prank(ownerAddress);
        pRBProxy.mintSpendooorPass(address1, limit);

        bytes memory transferPayload = abi.encodeWithSignature("mint(address)", address1);
        vm.prank(address1);
        pRBProxy.execute(address(ticket), 0.1 ether, transferPayload);
        vm.prank(address1);
        vm.expectRevert();
        pRBProxy.execute(address(ticket), 0.1 ether, transferPayload);
    }
}