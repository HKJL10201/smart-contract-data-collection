// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vote.sol";

contract VoteTest is Test {
    Vote public _vote;
    string[] x = ["one", "two", "three"];

    function setUp() public {
        _vote = new Vote();
    }

    function testIncrement() public {
        _vote.createVote("test", block.timestamp - 1, 100, x);
        assertEq(_vote.total(), 1);
        _vote.vote(0, 1);
        uint256[] memory firstVoteCount = _vote.getVoteSelectionCount(0);
        assertEq(firstVoteCount[1], 1);
        assertEq(firstVoteCount[0], 0);
    }
}
