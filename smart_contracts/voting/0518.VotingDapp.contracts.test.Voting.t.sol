// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Voting.sol";

contract CounterTest is Test {
    Voting public voting;
    address owner = address(0x1337);
    address deeps = address(0xb24156B92244C1541F916511E879e60710e30b84);
    address single = address(0x69420);
    bytes32[] proofArray;

    function setUp() public {
        vm.prank(owner);
        voting = new Voting(bytes32(0xa7e9577a96a6319368770efb7849268eb960562dccb373e9a8392a3fd59af139),uint64(block.timestamp +86400));

    }

    function test_Owner() public {
        assertEq(voting.owner(),owner);
    }

    // function test_verify() public {
    //     proofArray.push(bytes32(0x53425cdb00fded22285125fa62fd956c57f46244387ddc31ab943460c7371500));
    //     proofArray.push(bytes32(0x968ebbe24606fd5640403d23db40d641b6637f446fb6dfe1fd713f4cec12b04a));
    //     assertTrue(voting.verify(proofArray,0xb24156B92244C1541F916511E879e60710e30b84));
    // }

    function test_vote() public {
        vm.startPrank(deeps);
        proofArray.push(bytes32(0x53425cdb00fded22285125fa62fd956c57f46244387ddc31ab943460c7371500));
        proofArray.push(bytes32(0x968ebbe24606fd5640403d23db40d641b6637f446fb6dfe1fd713f4cec12b04a));
        voting.vote(proofArray, "Jasir");
        // assertEq(voting.votes("Jasir"),1);
        vm.stopPrank();

    }

    function test_voteAgain() public {
        test_vote();
        vm.expectRevert();
        vm.startPrank(deeps);
        voting.vote(proofArray, "Jasir");
        vm.stopPrank();

    }

    function test_addSingleAddress() public {
        vm.startPrank(owner);
        voting.updateSingle(single,1);
        vm.stopPrank();

    }

    function test_singleAddressVote() public {
        test_addSingleAddress();
        vm.startPrank(single);
        voting.vote(proofArray,"Jasir");
        vm.stopPrank();
        // assertEq(voting.votes("Jasir"),1);

    }

    function test_singleAndProo() public{
        test_vote();
        test_singleAddressVote();
        assertEq(voting.votes("Jasir"),2);

    }

    function test_voteBeforeTime() public {
        vm.expectRevert();
        test_vote();
    }

    function test_voteAfterTime() public {
        vm.warp(block.timestamp + 86400);
        test_vote();
    }


}
