// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { TestHelper } from "./Helper/TestHelper.t.sol";
import { Counter } from "../src/Counter.sol";
import { MyWallet } from "../src/MyWallet.sol";
import { MyWalletStorage } from "../src/MyWalletStorage.sol";
import { UserOperation } from "account-abstraction/interfaces/UserOperation.sol";

/** 
 * @dev test MyWallet & paying by PayMaster
 */ 
contract MyWalletPayMasterTest is TestHelper {

    function setUp() public override {
        super.setUp();

        // Deposit 100 ether to entry point for the paymaster
        entryPoint.depositTo{value: 100 ether}(address(payMaster));
        // Check if the paymaster has 100 ether in the entry point
        assertEq(entryPoint.balanceOf(address(payMaster)), 100 ether);

        // Fund 1000 test token to MyWallet
        deal(address(mockErc20), address(wallet), 1_000e18);
        assertEq(mockErc20.balanceOf(address(wallet)), 1_000e18);
    }

    // using test token to pay fee by payMaster
    function testPayByPayMaster() public {
        // wallet approve paymaster to use test token
        vm.prank(address(wallet));
        mockErc20.approve(address(payMaster), type(uint256).max);

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
        
        // Paymaster address and token address
        bytes memory paymasterAndData = abi.encodePacked(address(payMaster), address(mockErc20));
        UserOperation memory userOp = createUserOperation(sender, nonce, initCode, callData, paymasterAndData);
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
        // using test token to pay fee
        assertLt(mockErc20.balanceOf(address(wallet)), 1_000e18);
    }

}