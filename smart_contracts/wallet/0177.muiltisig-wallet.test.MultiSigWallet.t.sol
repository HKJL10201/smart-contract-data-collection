// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet multiSig;
    address[] owners;
    
    function setUp() public {
        owners.push(address(this));
        owners.push(address(1));
        owners.push(address(2));
        multiSig = new MultiSigWallet(owners);
    }

    function testSendEther() public {
        payable(address(multiSig)).transfer(1 ether);
        assertEq(address(multiSig).balance, 1 ether);
    }

    function testProposeTransaction() public {
        multiSig.proposeTransaction(address(0xdead), 1 ether);
        assertEq(multiSig.transactionsCount(), 1);
    }

    function testConfirmTransaction() public {
        multiSig.proposeTransaction(address(0xdead), 1 ether);
        multiSig.confirmTransaction(0);
        (, , , uint256 confirmations) = multiSig.getTransaction(0);
        assertEq(confirmations, 1);
    }

    function testRevokeConfirmation() public {
        multiSig.proposeTransaction(address(0xdead), 1 ether);
        multiSig.confirmTransaction(0);
        multiSig.revokeConfirmation(0);
        (, , , uint256 confirmations) = multiSig.getTransaction(0);
        assertEq(confirmations, 0);
    }

    function testDoTransaction() public {
        payable(address(multiSig)).transfer(1 ether);
        multiSig.proposeTransaction(address(0xdead), 1 ether);
        // 1st owner
        multiSig.confirmTransaction(0);
        // 2nd owner
        vm.prank(owners[1]);
        multiSig.confirmTransaction(0);
        // 3rd owner
        vm.prank(owners[2]);
        multiSig.confirmTransaction(0);
        // execute
        multiSig.executeTransaction(0);
        assertEq(address(0xdead).balance, 1 ether);
    }
}