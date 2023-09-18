// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { TestHelper } from "./Helper/TestHelper.t.sol";
import { Counter } from "../src/Counter.sol";
import { MyWallet } from "../src/MyWallet.sol";
import { MyWalletStorage } from "../src/MyWalletStorage.sol";
import { MyWalletV2ForTest } from "../src/MyWalletV2ForTest.sol";

/** 
 * @dev test directly interact with MyWallet through EOA
 */ 

contract MyWalletTest is TestHelper {
    function setUp() public override {
        super.setUp();
    }

    function testReceive() public {
        uint256 amount = 1 ether;
        vm.startPrank(someone);
        vm.expectEmit(true, true, true, true, address(wallet));
        emit Receive(someone, amount, amount);
        payable(address(wallet)).transfer(amount);
        vm.stopPrank();

        // check effects
        assertEq(address(wallet).balance, amount);
        assertEq(someone.balance, INIT_BALANCE - amount);
    }

    function testSubmitTransaction() public {
        // submit a transaction
        vm.startPrank(owners[0]);
        (bytes memory data, uint256 id) = submitTx();
        vm.stopPrank();

        // check effects
        assertEq(id, 0);
        (MyWallet.TransactionStatus status, 
        address to, 
        uint256 value, 
        bytes memory _data, 
        uint256 confirmNum, 
        uint256 timestamp) = wallet.getTransactionInfo(id);
        require(status == MyWalletStorage.TransactionStatus.PENDING, "status error");
        assertEq(to, address(counter));
        assertEq(value, 0);
        assertEq(data, _data);
        assertEq(confirmNum, 0);
        assertEq(timestamp, block.timestamp + timeLimit);
    }

    function testSubmitBySomeone() public {
        // submit a transaction
        vm.startPrank(someone);
        vm.expectRevert(MyWallet.NotOwner.selector);
        submitTx();
        vm.stopPrank();

    }

    function testConfirmTransaction() public {
        // submit a transaction
        vm.startPrank(owners[0]);
        (bytes memory data, uint256 id) = submitTx();
        // owners[0] confirm the transaction
        vm.expectEmit(true, true, true, true, address(wallet));
        emit ConfirmTransaction(address(owners[0]), id);
        wallet.confirmTransaction(id);
        vm.stopPrank();
        // owners[1] confirm the transaction
        vm.startPrank(owners[1]);
        vm.expectEmit(true, true, true, true, address(wallet));
        emit ConfirmTransaction(address(owners[1]), id);
        wallet.confirmTransaction(id);
        vm.stopPrank();
        
        // check effects
        (MyWallet.TransactionStatus status, 
        address to, 
        uint256 value, 
        bytes memory _data, 
        uint256 confirmNum, 
        uint256 timestamp) = wallet.getTransactionInfo(id);
        // status should be PASS after 2 confirm
        require(status == MyWalletStorage.TransactionStatus.PASS, "status error");
        assertEq(to, address(counter));
        assertEq(value, 0);
        assertEq(data, _data);
        assertEq(confirmNum, 2);
        assertEq(timestamp, block.timestamp + timeLimit);
        assertTrue(wallet.isConfirmed(id, owners[0]));
        assertTrue(wallet.isConfirmed(id, owners[1]));
    }

    function testConfirmBySomeone() public {
        // submit a transaction
        vm.startPrank(owners[0]);
        (, uint256 id) = submitTx();
        vm.stopPrank();

        // someone confirm the transaction
        vm.startPrank(someone);
        vm.expectRevert(MyWallet.NotOwner.selector);
        wallet.confirmTransaction(id);
        vm.stopPrank();
    }

    function testExecuteTransaction() public {
        // submit a transaction
        vm.startPrank(owners[0]);
        (, uint256 id) = submitTx();
        // owners[0] confirm the transaction
        vm.expectEmit(true, true, true, true, address(wallet));
        emit ConfirmTransaction(address(owners[0]), id);
        wallet.confirmTransaction(id);
        vm.stopPrank();
        // owners[1] confirm the transaction
        vm.startPrank(owners[1]);
        wallet.confirmTransaction(id);
        vm.stopPrank();
        // everyone can call execute
        vm.expectEmit(true, true, true, true, address(wallet));
        emit ExecuteTransaction(id);
        wallet.executeTransaction(id);

        // check effects
        assertEq(counter.number(), 1);
    }

    function testOverTime() public {
        // submit a transaction
        vm.startPrank(owners[0]);
        (, uint256 id) = submitTx();
        vm.stopPrank();

        (MyWallet.TransactionStatus status, , , , , ) = wallet.getTransactionInfo(id);
        require(status == MyWalletStorage.TransactionStatus.PENDING, "status error");

        // overtime
        skip(1 days + 1);

        // check effects
        assertEq(id, 0);
        (status, , , , , ) = wallet.getTransactionInfo(id);
        require(status == MyWalletStorage.TransactionStatus.OVERTIME, "status error");
    }

    function testSubmitTransactionToWhiteListAndExecute() public{
        // submit a transaction
        uint256 amount = 1 ether;
        vm.startPrank(owners[0]);
        (bytes memory data, uint256 id) = submitTxWhiteList(amount);
        // owners[0] confirm the transaction
        vm.expectEmit(true, true, true, true, address(wallet));
        emit ConfirmTransaction(address(owners[0]), id);
        wallet.confirmTransaction(id);
        vm.stopPrank();

        // check effects
        assertEq(id, 0);
        (MyWallet.TransactionStatus status, 
        address to, 
        uint256 value, 
        bytes memory _data, 
        uint256 confirmNum, 
        uint256 timestamp) = wallet.getTransactionInfo(id);
        require(status == MyWalletStorage.TransactionStatus.PASS, "status error");
        assertEq(to, whiteList[0]);
        assertEq(value, amount);
        assertEq(data, _data);
        assertEq(confirmNum, 1);
        assertEq(timestamp, block.timestamp + timeLimit);
        assertTrue(wallet.isConfirmed(id, owners[0]));

        // execute the transaction
        payable(address(wallet)).transfer(amount);
        vm.expectEmit(true, true, true, true, address(wallet));
        emit ExecuteTransaction(id);
        wallet.executeTransaction(id);

        // check effects
        assertEq(whiteList[0].balance, amount);
    }

    function testFreezeWallet() public {
        // freeze wallet
        vm.startPrank(owners[0]);
        wallet.freezeWallet();
        vm.stopPrank();

        // check effects
        assertTrue(wallet.isFreezing());
    }

    function testFreezeWalletBySomeone() public {
        // freeze wallet
        vm.startPrank(someone);
        vm.expectRevert(MyWallet.NotOwner.selector);
        wallet.freezeWallet();
        vm.stopPrank();
    }

    function testUnfreezeWallet() public {
        // freeze wallet
        vm.startPrank(owners[0]);
        wallet.freezeWallet();
        vm.stopPrank();

        // check effects
        assertTrue(wallet.isFreezing());

        // unfreeze wallet
        uint256 round = 0;
        vm.prank(owners[0]);
        wallet.unfreezeWallet();
        assertTrue(wallet.unfreezeBy(round, owners[0]));
        assertEq(wallet.unfreezeCounter(), 1);

        vm.prank(owners[1]);
        wallet.unfreezeWallet();

        // cehck effects
        assertFalse(wallet.isFreezing());
        assertEq(wallet.unfreezeRound(), round + 1);
        assertEq(wallet.unfreezeCounter(), 0);
    }

    function testSubmitRecovery() public {
        // submit recovery
        (address replacedOwner, address newOwner) = submitRecovery();

        // check effects
        (address addr1, address addr2, uint256 num) = wallet.getRecoveryInfo();
        assertEq(addr1, replacedOwner);
        assertEq(addr2, newOwner);
        assertEq(num, 0);
        assertTrue(wallet.isRecovering());
    }

    function testSupportRecovery() public {
        // submit recovery
        (address replacedOwner, address newOwner) = submitRecovery();

        // support recovery
        vm.prank(guardians[0]);
        wallet.supportRecovery();

        // check effects
        (address addr1, address addr2, uint256 num) = wallet.getRecoveryInfo();
        assertEq(addr1, replacedOwner);
        assertEq(addr2, newOwner);
        assertEq(num, 1);
        assertTrue(wallet.recoverBy(0, guardians[0]));
    }

    function testExecuteRecovery() public {
        // submit recovery
        (address replacedOwner, address newOwner) = submitRecovery();

        // support recovery
        vm.prank(guardians[0]);
        wallet.supportRecovery();
        vm.prank(guardians[1]);
        wallet.supportRecovery();
        
        // execute Recovery
        vm.prank(owners[0]);
        wallet.executeRecovery();

        // check effects
        assertTrue(wallet.isOwner(newOwner));
        assertFalse(wallet.isOwner(replacedOwner));
        assertFalse(wallet.isRecovering());
        assertEq(wallet.recoverRound(), 1);
        (address addr1, address addr2, uint256 num) = wallet.getRecoveryInfo();
        assertEq(addr1, address(0));
        assertEq(addr2, address(0));
        assertEq(num, 0);
    }

    function testErc721Receive() public {
        // someone mint erc721 and transfer to wallet
        vm.startPrank(someone);
        uint256 tokenId = 0;
        mockErc721.mint(someone, tokenId);
        mockErc721.safeTransferFrom(someone, address(wallet), tokenId);
        vm.stopPrank();

        // check effects
        assertEq(mockErc721.balanceOf(address(wallet)), 1);
    }

    function testErc1155Receive() public {
        // someone mint erc1155 and transfer to wallet
        vm.startPrank(someone);
        uint256 tokenId = 0;
        uint256 amount = 1;
        mockErc1155.mint(someone, tokenId, amount, "");
        mockErc1155.safeTransferFrom(someone, address(wallet), tokenId, amount, "");
        vm.stopPrank();

        // check effects
        assertEq(mockErc1155.balanceOf(address(wallet), tokenId), 1);
    }

    function testAddWhiteList() public {
        // submit add white list tx (add someone on white list)
        vm.startPrank(owners[0]);
        bytes memory data = abi.encodeCall(MyWallet.addWhiteList, (someone));
        uint256 id = wallet.submitTransaction(address(wallet), 0, data);
        vm.stopPrank();

        // owners[0] and owners[1] confirm transaction
        vm.prank(owners[0]);
        wallet.confirmTransaction(id);
        vm.prank(owners[1]);
        wallet.confirmTransaction(id);

        // execute transaction 
        wallet.executeTransaction(id);

        // check effects
        assertTrue(wallet.isWhiteList(someone));
    }

    function testRemoveWhiteList() public {
        // submit remove white list tx
        vm.startPrank(owners[0]);
        bytes memory data = abi.encodeCall(MyWallet.removeWhiteList, (whiteList[0]));
        uint256 id = wallet.submitTransaction(address(wallet), 0, data);
        vm.stopPrank();

        // owners[0] and owners[1] confirm transaction
        vm.prank(owners[0]);
        wallet.confirmTransaction(id);
        vm.prank(owners[1]);
        wallet.confirmTransaction(id);

        // execute transaction 
        wallet.executeTransaction(id);

        // check effects
        assertFalse(wallet.isWhiteList(whiteList[0]));
    }

    function testReplaceGuardian() public {
        // submit replaceGuardian tx (add someone as new guardian)
        vm.startPrank(owners[0]);
        bytes32 newGuardianHash = keccak256(abi.encodePacked(someone));
        bytes memory data = abi.encodeCall(MyWallet.replaceGuardian, (guardianHashes[0], newGuardianHash));
        uint256 id = wallet.submitTransaction(address(wallet), 0, data);
        vm.stopPrank();

        // owners[0] and owners[1] confirm transaction
        vm.prank(owners[0]);
        wallet.confirmTransaction(id);
        vm.prank(owners[1]);
        wallet.confirmTransaction(id);

        // execute transaction 
        wallet.executeTransaction(id);

        // check effects
        assertTrue(wallet.isGuardian(newGuardianHash));
        assertFalse(wallet.isGuardian(guardianHashes[0]));
    }

    function testUUPSUpgrade() public {
        // submit tx to upgrade to V2
        MyWalletV2ForTest newImpl = new MyWalletV2ForTest(entryPoint);
        vm.startPrank(owners[0]);
        bytes memory upgradeData = abi.encodeCall(MyWalletV2ForTest.initializeV2, ());
        bytes memory data = abi.encodeCall(MyWallet.upgradeToAndCall, (address(newImpl), upgradeData));
        uint256 id = wallet.submitTransaction(address(wallet), 0, data);
        vm.stopPrank();

        // owners[0] and owners[1] confirm transaction
        vm.prank(owners[0]);
        wallet.confirmTransaction(id);
        vm.prank(owners[1]);
        wallet.confirmTransaction(id);

        // execute transaction 
        wallet.executeTransaction(id);

        // check effects
        assertEq(MyWalletV2ForTest(address(wallet)).testNum(), 2);
    }

}