// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Admin.sol";

contract User {}

contract TestAdmin is Test {
    Admin admin;
    User alice;
    User bob;

    function setUp() public {
        alice = new User();
        bob = new User();

        admin = new Admin();
    }

    function testOwnership() public {
        assertEq(admin.owner(), address(this));
    }

    function testTransferOwnership() public {
        admin.transferOwnership(address(alice));
        assertEq(admin.owner(), address(alice));
    }

    function testTransferOwnershipRevert() public {
        vm.expectRevert("Only owner can call this function.");
        vm.prank(address(bob));
        admin.transferOwnership(address(bob));
    }
}
