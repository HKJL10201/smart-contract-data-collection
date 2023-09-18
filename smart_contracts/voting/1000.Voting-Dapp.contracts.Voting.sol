// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Voting {
    struct Voter {
        bool voted;
        uint256 vote;
        uint256 weight;
    }

    struct Proposal {
        bytes32 name;
        uint256 voteCount;
    }

    Proposal[] public proposals;
    mapping(address => Voter) public voters;
    address public chairperson;

    // will add proposal names when the contract will be deployed
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    // function to give right to vote
    function giveRightToVote(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote"
        );
        require(!voters[voter].voted, "Voter Already voted");
        voters[voter].weight = 1;
    }

    // function to vote
    function vote(uint256 proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You don't have right to vote");
        require(!sender.voted, "Already Voted");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }

    // function for finding the winner of election
    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 maxVoteCount = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > maxVoteCount) {
                maxVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }

    // function to get the winner id
    function winnerId() public view returns (uint256 winnerId_) {
        winnerId_ = winningProposal();
    }
}
