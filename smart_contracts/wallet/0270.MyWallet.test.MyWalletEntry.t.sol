// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { TestHelper } from "./Helper/TestHelper.t.sol";
import { Counter } from "../src/Counter.sol";
import { MyWallet } from "../src/MyWallet.sol";
import { MyWalletStorage } from "../src/MyWalletStorage.sol";
import { UserOperation } from "account-abstraction/interfaces/UserOperation.sol";
import { MyWalletFactory } from "../src/MyWalletFactory.sol";
import "forge-std/console.sol";

/** 
 * @dev test interact with MyWallet through EntryPoint
 *      This part we deposit ETH into EntryPoint to pay for tx
 */ 

contract MyWalletEntryTest is TestHelper {
    uint256 constant DEPOSIT_VALUE = 5 ether;
    function setUp() public override {
        super.setUp();

        // deposit eth for wallet
        vm.prank(owners[0]);
        entryPoint.depositTo{value: DEPOSIT_VALUE}(address(wallet));
        assertEq(entryPoint.balanceOf(address(wallet)), DEPOSIT_VALUE);
    }

    function testEntrySimulateValidation() public {
        // create userOperation
        vm.startPrank(owners[0]);
        address sender = address(wallet);
        uint256 nonce = wallet.getNonce();
        bytes memory initCode = "";
        bytes memory callData = abi.encodeCall(
            MyWallet.submitTransaction, 
            (
                address(counter), 
                0, 
                abi.encodeCall(Counter.increment, ())
            ));
        UserOperation memory userOp = createUserOperation(sender, nonce, initCode, callData);
        // sign 
        userOp.signature = signUserOp(userOp, ownerKeys[0]);
        vm.stopPrank();

        // bundler simulate Operation
        // Successful result is ValidationResult error.
        vm.startPrank(bundler);
        vm.expectRevert();
        entryPoint.simulateValidation(userOp); // should be done offchain
        // "ValidationResult((58755, 16100000000000000, false, 0, 281474976710655, 0x), (0, 0), (0, 0), (0, 0))"
        vm.stopPrank();
    }

    // use userOperation to create a new wallet
    function testCreateWallet() public {
        // create userOperation
        // get account address before create
        vm.startPrank(owners[0]);
        address sender = factory.getAddress(
                owners, 
                confirmThreshold, 
                guardianHashes, 
                recoverThreshold, 
                whiteList, 
                123
                );
        uint256 nonce = 0;
        bytes memory data = abi.encodeCall(
            MyWalletFactory.createAccount, 
            (
                owners, 
                confirmThreshold, 
                guardianHashes, 
                recoverThreshold, 
                whiteList, 
                123
                ));
        bytes memory initCode = abi.encodePacked(address(factory), data);
        UserOperation memory userOp = createUserOperation(sender, nonce, initCode, "");
        // sign 
        userOp.signature = signUserOp(userOp, ownerKeys[0]);
        // deposit 
        entryPoint.depositTo{value: DEPOSIT_VALUE}(address(sender));
        assertEq(entryPoint.balanceOf(address(sender)), DEPOSIT_VALUE);
        vm.stopPrank();

        UserOperation[] memory ops;
        ops = new UserOperation[](1);
        ops[0] = userOp;

        // bundler send operation to entryPoint
        vm.prank(bundler);
        entryPoint.handleOps(ops, payable(bundler));

        //check effects
        assertEq(MyWallet(sender).leastConfirmThreshold(), confirmThreshold);
        // pay with deposited ether
        assertLt(entryPoint.balanceOf(address(sender)), DEPOSIT_VALUE);
    }

    function testEntrySubmitTransaction() public {
        // create userOperation
        vm.startPrank(owners[0]);
        address sender = address(wallet);
        uint256 nonce = wallet.getNonce();
        bytes memory initCode = "";
        bytes memory callData = abi.encodeCall(
            MyWallet.submitTransaction, 
            (
                address(counter), 
                0, 
                abi.encodeCall(Counter.increment, ())
            ));
        UserOperation memory userOp = createUserOperation(sender, nonce, initCode, callData);
        // sign 
        userOp.signature = signUserOp(userOp, ownerKeys[0]);
        vm.stopPrank();

        UserOperation[] memory ops;
        ops = new UserOperation[](1);
        ops[0] = userOp;

        // bundler send operation to entryPoint
        vm.prank(bundler);
        entryPoint.handleOps(ops, payable(bundler));

        // check effects
        (MyWallet.TransactionStatus status, 
        address to, 
        uint256 value, 
        bytes memory data, 
        uint256 confirmNum, 
        uint256 timestamp) = wallet.getTransactionInfo(0);
        require(status == MyWalletStorage.TransactionStatus.PENDING, "status error");
        assertEq(to, address(counter));
        assertEq(value, 0);
        assertEq(data, abi.encodeCall(Counter.increment, ()));
        assertEq(confirmNum, 0);
        assertEq(timestamp, block.timestamp + timeLimit);
        // pay with deposited ether
        assertLt(entryPoint.balanceOf(address(wallet)), DEPOSIT_VALUE);
    }

    function testConfirmTransaction() public {
        testEntrySubmitTransaction();
        // create userOperation
        vm.startPrank(owners[0]);
        address sender = address(wallet);
        uint256 nonce = wallet.getNonce();
        bytes memory initCode = "";
        bytes memory callData = abi.encodeCall(MyWallet.confirmTransaction, (0));
        UserOperation memory userOp = createUserOperation(sender, nonce, initCode, callData);
        // sign 
        userOp.signature = signUserOp(userOp, ownerKeys[0]);
        vm.stopPrank();

        UserOperation[] memory ops;
        ops = new UserOperation[](1);
        ops[0] = userOp;

        // bundler send operation to entryPoint
        vm.prank(bundler);
        entryPoint.handleOps(ops, payable(bundler));

        // check effects
        (, , , , uint256 confirmNum, ) = wallet.getTransactionInfo(0);
        assertEq(confirmNum, 1);
        assertTrue(wallet.isConfirmed(0, owners[0]));
        // pay with deposited ether
        assertLt(entryPoint.balanceOf(address(wallet)), DEPOSIT_VALUE);
    }

    function testEntryExecuteTransaction() public {
        testConfirmTransaction();
        // confirm by owners[1]
        vm.startPrank(owners[1]);
        wallet.confirmTransaction(0);
        vm.stopPrank();

        // create userOperation
        vm.startPrank(owners[0]);
        address sender = address(wallet);
        uint256 nonce = wallet.getNonce();
        bytes memory initCode = "";
        bytes memory callData = abi.encodeCall(MyWallet.executeTransaction, (0));
        UserOperation memory userOp = createUserOperation(sender, nonce, initCode, callData);
        // sign 
        userOp.signature = signUserOp(userOp, ownerKeys[0]);
        vm.stopPrank();

        UserOperation[] memory ops;
        ops = new UserOperation[](1);
        ops[0] = userOp;

        // bundler send operation to entryPoint
        vm.prank(bundler);
        entryPoint.handleOps(ops, payable(bundler));

        // check effects
        assertEq(counter.number(), 1);
        // pay with deposited ether
        assertLt(entryPoint.balanceOf(address(wallet)), DEPOSIT_VALUE);
    }

    function testEntrySubmitRecovery() public {
        // create userOperation
        vm.startPrank(guardians[0]);
        address sender = address(wallet);
        uint256 nonce = wallet.getNonce();
        bytes memory initCode = "";
        bytes memory callData = abi.encodeCall(MyWallet.submitRecovery, (owners[2], someone));
        UserOperation memory userOp = createUserOperation(sender, nonce, initCode, callData);
        // sign 
        userOp.signature = signUserOp(userOp, guardianKeys[0]);
        vm.stopPrank();

        UserOperation[] memory ops;
        ops = new UserOperation[](1);
        ops[0] = userOp;

        // bundler send operation to entryPoint
        vm.prank(bundler);
        entryPoint.handleOps(ops, payable(bundler));

        // check effects
        (address addr1, address addr2, uint256 num) = wallet.getRecoveryInfo();
        assertEq(addr1, owners[2]);
        assertEq(addr2, someone);
        assertEq(num, 0);
        assertTrue(wallet.isRecovering());
        // pay with deposited ether
        assertLt(entryPoint.balanceOf(address(wallet)), DEPOSIT_VALUE);
    }

    function testEntrySupportRecovery() public {
        testEntrySubmitRecovery();
        // create userOperation
        vm.startPrank(guardians[0]);
        address sender = address(wallet);
        uint256 nonce = wallet.getNonce();
        bytes memory initCode = "";
        bytes memory callData = abi.encodeCall(MyWallet.supportRecovery, ());
        UserOperation memory userOp = createUserOperation(sender, nonce, initCode, callData);
        // sign 
        userOp.signature = signUserOp(userOp, guardianKeys[0]);
        vm.stopPrank();

        UserOperation[] memory ops;
        ops = new UserOperation[](1);
        ops[0] = userOp;

        // bundler send operation to entryPoint
        vm.prank(bundler);
        entryPoint.handleOps(ops, payable(bundler));

        // check effects
        (, , uint256 num) = wallet.getRecoveryInfo();
        assertEq(num, 1);
        assertTrue(wallet.recoverBy(0, guardians[0]));
        // pay with deposited ether
        assertLt(entryPoint.balanceOf(address(wallet)), DEPOSIT_VALUE);
    }

    function testEntryExecuteRecovery() public {
        testEntrySupportRecovery();

        vm.prank(guardians[1]);
        wallet.supportRecovery();

        // create userOperation
        vm.startPrank(owners[0]);
        address sender = address(wallet);
        uint256 nonce = wallet.getNonce();
        bytes memory initCode = "";
        bytes memory callData = abi.encodeCall(MyWallet.executeRecovery, ());
        UserOperation memory userOp = createUserOperation(sender, nonce, initCode, callData);
        // sign 
        userOp.signature = signUserOp(userOp, ownerKeys[0]);
        vm.stopPrank();

        UserOperation[] memory ops;
        ops = new UserOperation[](1);
        ops[0] = userOp;

        // bundler send operation to entryPoint
        vm.prank(bundler);
        entryPoint.handleOps(ops, payable(bundler));

        // check effects
        assertTrue(wallet.isOwner(someone));
        assertFalse(wallet.isOwner(owners[2]));
        assertFalse(wallet.isRecovering());
        assertEq(wallet.recoverRound(), 1);
        (address addr1, address addr2, uint256 num) = wallet.getRecoveryInfo();
        assertEq(addr1, address(0));
        assertEq(addr2, address(0));
        assertEq(num, 0);
        // pay with deposited ether
        assertLt(entryPoint.balanceOf(address(wallet)), DEPOSIT_VALUE);
    }

    function testEntryFreezeWallet() public {
        // create userOperation
        vm.startPrank(owners[0]);
        address sender = address(wallet);
        uint256 nonce = wallet.getNonce();
        bytes memory initCode = "";
        bytes memory callData = abi.encodeCall(MyWallet.freezeWallet, ());
        UserOperation memory userOp = createUserOperation(sender, nonce, initCode, callData);
        // sign 
        userOp.signature = signUserOp(userOp, ownerKeys[0]);
        vm.stopPrank();

        UserOperation[] memory ops;
        ops = new UserOperation[](1);
        ops[0] = userOp;

        // bundler send operation to entryPoint
        vm.prank(bundler);
        entryPoint.handleOps(ops, payable(bundler));

        // check effects
        assertTrue(wallet.isFreezing());
        // pay with deposited ether
        assertLt(entryPoint.balanceOf(address(wallet)), DEPOSIT_VALUE);
    }

    function testEntryUnfreezeWallet() public {
        testEntryFreezeWallet();
        // create userOperation
        vm.startPrank(owners[0]);
        address sender = address(wallet);
        uint256 nonce = wallet.getNonce();
        bytes memory initCode = "";
        bytes memory callData = abi.encodeCall(MyWallet.unfreezeWallet, ());
        UserOperation memory userOp = createUserOperation(sender, nonce, initCode, callData);
        // sign 
        userOp.signature = signUserOp(userOp, ownerKeys[0]);
        vm.stopPrank();

        UserOperation[] memory ops;
        ops = new UserOperation[](1);
        ops[0] = userOp;

        // bundler send operation to entryPoint
        vm.prank(bundler);
        entryPoint.handleOps(ops, payable(bundler));

        assertTrue(wallet.unfreezeBy(0, owners[0]));
        assertEq(wallet.unfreezeCounter(), 1);
        // pay with deposited ether
        assertLt(entryPoint.balanceOf(address(wallet)), DEPOSIT_VALUE);
    }

}