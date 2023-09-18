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

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {MockToken} from "../src/MockToken.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import "forge-std/console.sol";
import "forge-std/StdUtils.sol";

/// @title MockTokenTest
/// @author 0xValerius
/// @notice A test contract for testing the MultiSigWallet contract with a MockToken.
contract MockTokenTest is Test {
    MockToken token;
    MultiSigWallet multisig;

    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);

    address[] owners = [owner1, owner2, owner3];
    address user = address(0x4);

    /// @notice Sets up the initial state of the test contract, including deploying the MockToken and MultiSigWallet contracts.
    function setUp() public {
        // load address ether balances
        vm.deal(owner1, 1000);
        vm.deal(owner2, 1000);
        vm.deal(owner3, 1000);
        vm.deal(user, 1000);

        // deploy MockToken
        token = new MockToken('MockToken', 'MTK');

        // load MockToken balances
        deal(address(token), owner1, 1000, true);
        deal(address(token), owner2, 1000, true);
        deal(address(token), owner3, 1000, true);
        deal(address(token), user, 1000, true);

        // deploy MuliSigWallet
        multisig = new MultiSigWallet(owners, 2);

        // Send ether and token to MultiSigWallet
        vm.startPrank(owner1);
        (bool success,) = address(multisig).call{value: 100}("");
        require(success, "Error sending Ether.");
        token.transfer(address(multisig), 100);
        vm.stopPrank();
    }

    /// @notice Tests the initial balances of actors in the contract.
    function test_ActorsBalance() public {
        // Check Ether Balance
        assertEq(owner1.balance, 900);
        assertEq(owner2.balance, 1000);
        assertEq(owner3.balance, 1000);
        assertEq(user.balance, 1000);

        // Check Mocked Token Balance
        assertEq(token.balanceOf(owner1), 900);
        assertEq(token.balanceOf(owner2), 1000);
        assertEq(token.balanceOf(owner3), 1000);
        assertEq(token.balanceOf(user), 1000);

        // Check Mocked Token Total Supply
        assertEq(token.totalSupply(), 4000);
    }

    /// @notice Tests the deployment of the MultiSigWallet contract.
    function test_MultiSigDeploy() public {
        // Check MultiSigWallet owners
        assertEq(multisig.owners(0), owner1);
        assertEq(multisig.owners(1), owner2);
        assertEq(multisig.owners(2), owner3);
        assertEq(multisig.isOwner(owner1), true);
        assertEq(multisig.isOwner(owner2), true);
        assertEq(multisig.isOwner(owner3), true);
        assertEq(multisig.isOwner(user), false);
    }

    /// @notice Tests the balances of the MultiSigWallet after transferring ether and tokens.
    function test_CheckMultiSigBalance() public {
        // Check final ether and mock token balance after transfer
        assertEq(address(multisig).balance, 100);
        assertEq(token.balanceOf(address(multisig)), 100);
        assertEq(token.balanceOf(owner1), 900);
    }

    /// @notice Tests the submission of transactions by the MultiSigWallet contract.
    function test_SubmitTransaction() public {
        // Test onlyOwner submit transaction
        vm.startPrank(owner1);
        multisig.submitTransaction(user, 10, "");
        vm.stopPrank();

        // Check transaction data
        (address proposer, address to, uint256 value, bytes memory data, bool executed) = multisig.transactions(0);
        assertEq(proposer, owner1);
        assertEq(to, user);
        assertEq(value, 10);
        assertEq(data, "");
        assertEq(executed, false);

        // Revert when not owner
        vm.expectRevert();
        vm.startPrank(user);
        multisig.submitTransaction(user, 10, "");
        vm.stopPrank();
    }

    /// @notice Tests the approval of transactions by the MultiSigWallet contract.
    function test_ApproveTransaction() public {
        // Submit a transaction
        vm.startPrank(owner1);
        multisig.submitTransaction(user, 10, "");
        vm.stopPrank();

        // Approve transaction
        vm.startPrank(owner2);
        multisig.approveTransaction(0);
        vm.stopPrank();

        // Check approval
        assertEq(multisig.isConfirmed(0, owner1), true);
        assertEq(multisig.isConfirmed(0, owner2), true);

        // Rever when user try transaction approval
        vm.expectRevert();
        vm.startPrank(user);
        multisig.approveTransaction(0);
        vm.stopPrank();
    }

    /// @notice Tests the execution of transactions by the MultiSigWallet contract.
    function test_ExecuteTransaction() public {
        // Submit a transaction
        vm.startPrank(owner1);
        multisig.submitTransaction(user, 10, "");
        vm.stopPrank();

        // Approve transaction
        vm.startPrank(owner2);
        multisig.approveTransaction(0);
        vm.stopPrank();

        // Execute transaction
        vm.startPrank(owner3);
        multisig.executeTransaction(0);
        vm.stopPrank();

        // Verifiy transactione execution
        (,,,, bool executed) = multisig.transactions(0);
        assertEq(executed, true);
        assertEq(user.balance, 1010);
    }

    /// @notice Tests the submission of token transactions by the MultiSigWallet contract.
    function test_SubmitTokenTransaction() public {
        // Test onlyOwner submit transaction
        vm.startPrank(owner1);
        multisig.submitTokenTransaction(address(token), user, 10);
        vm.stopPrank();

        // Check transaction data
        (address proposer, address to, uint256 value, bytes memory data, bool executed) = multisig.transactions(0);

        assertEq(proposer, owner1);
        assertEq(to, address(token));
        assertEq(value, 0);
        assertEq(data, abi.encodeWithSignature("transfer(address,uint256)", user, 10));
        assertEq(executed, false);
    }

    /// @notice Tests the execution of token transactions by the MultiSigWallet contract.
    function test_ExecuteTokenTransaction() public {
        // Submit a transaction
        vm.startPrank(owner1);
        multisig.submitTokenTransaction(address(token), user, 10);
        vm.stopPrank();

        // Approve transaction
        vm.startPrank(owner2);
        multisig.approveTransaction(0);
        vm.stopPrank();

        // Execute transaction
        vm.startPrank(owner3);
        multisig.executeTransaction(0);
        vm.stopPrank();

        // Verifiy transactione execution
        (,,,, bool executed) = multisig.transactions(0);
        assertEq(executed, true);
        assertEq(token.balanceOf(user), 1010);
    }
}
