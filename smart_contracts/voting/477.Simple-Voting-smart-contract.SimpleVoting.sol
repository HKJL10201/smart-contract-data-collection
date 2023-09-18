// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Voting {
    uint public totalVotes;
    mapping(uint => uint) public votes;       //votes mapping tracks the number of votes received for each proposal.

//he vote function accepts a proposal as an argument and 
//increments the vote count for that proposal in the votes mapping

    function vote(uint proposal) public {
        require(proposal >= 0 && proposal <= 1, "Invalid proposal.");
        votes[proposal]++;
        totalVotes++;
    }

// winningProposal function returns the winning proposal by iterating through the votes mapping 
//and finding the proposal with the highest number of votes.

    function winningProposal() public view returns (uint) {
        uint winningVoteCount = 0;
        uint winningProposal;
        for (uint p = 0; p <= 1; p++) {
            if (votes[p] > winningVoteCount) {
                winningVoteCount = votes[p];
                winningProposal = p;
            }
        }
        return winningProposal;
    }
}
