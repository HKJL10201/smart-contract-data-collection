// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VotingSystem.sol";

contract FirstPastThePost is VotingSystem {
    constructor(IERC20 _requiredToken) VotingSystem(_requiredToken) {}

    function getWinnerFPTP(uint256 _pollId) public view returns (uint256) {
        require(polls[_pollId].ended, "Poll has not ended.");

        uint256 highestVoteCount = 0;
        uint256 winningOptionIndex = 0;

        for (uint256 i = 0; i < polls[_pollId].voteCounts.length; i++) {
            if (polls[_pollId].voteCounts[i] > highestVoteCount) {
                highestVoteCount = polls[_pollId].voteCounts[i];
                winningOptionIndex = i;
            }
        }

        return winningOptionIndex;
    }
}
