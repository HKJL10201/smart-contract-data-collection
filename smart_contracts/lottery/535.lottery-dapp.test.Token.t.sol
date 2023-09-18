// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Token.sol";

contract User {}

contract TestToken is Test {
    uint256 TOTAL_SUPPLY = 1_000_000_000;
    Token token;

    User alice;
    User bob;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        token = new Token(TOTAL_SUPPLY);

        alice = new User();
        bob = new User();
    }

    function testSupply() public {
        assertEq(token.totalSupply(), TOTAL_SUPPLY);
    }

    function testBalanceOf() public {
        assertEq(token.balanceOf(address(this)), token.totalSupply());
    }

    function testTransfer() public {
        token.transfer(address(alice), 100);
        assertEq(token.balanceOf(address(this)), TOTAL_SUPPLY - 100);
        assertEq(token.balanceOf(address(alice)), 100);
    }

    function testTransferEvent() public {
        vm.expectEmit(true, true, true, true, address(token));
        emit Transfer(address(this), address(alice), 100);

        token.transfer(address(alice), 100);
    }

    function testAllowance() public {
        vm.expectEmit(true, true, true, true, address(token));
        emit Approval(address(this), address(alice), 500);

        token.approve(address(alice), 500);

        assertEq(token.balanceOf(address(alice)), 0);
        assertEq(token.balanceOf(address(this)), TOTAL_SUPPLY);
        assertEq(token.allowance(address(this), address(alice)), 500);
    }

    function testAllowanceTransfer() public {
        token.approve(address(alice), 500);
        assertEq(token.allowance(address(this), address(alice)), 500);

        vm.expectEmit(true, true, true, true, address(token));
        emit Transfer(address(this), address(bob), 300);

        vm.prank(address(alice));
        token.transferFrom(address(this), address(bob), 300);

        assertEq(token.allowance(address(this), address(alice)), 200);
        assertEq(token.balanceOf(address(bob)), 300);
        assertEq(token.balanceOf(address(this)), TOTAL_SUPPLY - 300);
    }
}
