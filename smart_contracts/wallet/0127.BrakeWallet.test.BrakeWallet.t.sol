// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "../src/BrakeWallet.sol";

contract BrakeWalletTest is Test {
    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed from, uint256 amount);

    BrakeWallet public wallet;

    function setUp() public {
        wallet = new BrakeWallet(1 ether, 1 hours);
    }

    function testDeposit() public {
        vm.deal(msg.sender, 1 ether);

        vm.expectEmit(true, false, false, false);
        emit Deposit(address(this), 1 ether);
        wallet.deposit{value: 1 ether}();

        assert(address(wallet).balance == 1 ether);
        assert(wallet.balanceOf(address(this)) > 0);
    }

    function testWithdraw() public {
        vm.deal(msg.sender, 2 ether);

        wallet.deposit{value: 2 ether}();

        assert(wallet.balanceOf(address(this)) == 2 ether);
        assert(address(wallet).balance == 2 ether);

        vm.expectEmit(true, false, false, true);
        emit Withdrawal(address(this), 1 ether);
        wallet.withdraw(1 ether);
        // Test that the wallet is rate limited correctly
        vm.expectRevert();
        wallet.withdraw(1 ether);
        // Warp an hour, to get over the period
        vm.warp(block.timestamp + 1 hours);

        wallet.withdraw(1 ether);

        assert(address(wallet).balance == 0);
        assert(wallet.balanceOf(address(this)) == 0);
    }

    function testWithdrawRateLimit(uint96 amount) public {
        wallet.deposit{value: address(this).balance}();

        vm.assume(amount > 1 ether);

        vm.expectRevert();
        wallet.withdraw(amount);
    }

    function testWithdrawSuccessful(uint96 amount) public {
        vm.assume(amount < 1 ether);

        vm.expectEmit(true, false, false, true);
        emit Deposit(address(this), address(this).balance);
        wallet.deposit{value: address(this).balance}();

        vm.expectEmit(true, false, false, true);
        emit Withdrawal(address(this), amount);
        wallet.withdraw(amount);
    }

    receive() external payable {}
}
