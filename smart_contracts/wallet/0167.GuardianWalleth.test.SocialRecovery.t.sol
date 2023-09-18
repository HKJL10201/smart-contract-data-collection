// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SocialRecovery.sol";

contract SocialRecoveryTest is Test {
    address[] guardians;
    address guardian1 = address(0xABCD);
    address guardian2 = address(0xABDC);
    SocialRecovery socialRecovery;
    function setUp() public {
        vm.prank(address(0xAA));
        guardians.push(address(0xABCD));
        guardians.push(address(0xABDC));
        socialRecovery = new SocialRecovery(guardians);
    }


    function testOwnerChange() public 
    {
        vm.prank(guardian1);
        bool isOwnerChanged = socialRecovery.castVote(address(0xABCC));
        assertEq(isOwnerChanged, false);
        vm.prank(guardian2);
        isOwnerChanged = socialRecovery.castVote(address(0xABCC));
        assertEq(isOwnerChanged, true);
    }
    
}
