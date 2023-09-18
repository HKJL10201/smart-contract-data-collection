pragma solidity ^0.4.11;


contract Ballot {

    struct Voter {
        bool voted;
        uint vote;
    }

    struct Proposal {
        uint voteCount;
    }

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    function Ballot(uint _numProposals) {
        proposals.length = _numProposals;
        for (uint p = 0; p < proposals.length; p++) {
            proposals[p].voteCount = 0;
        }
    }

    function vote(uint proposal) {
        Voter sender = voters[msg.sender];
        require(!sender.voted);
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += 1;
    }

    function winningProposal() constant
            returns (uint winningProposal)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal = p;
            }
        }
    }

    function getVoteCount(uint num) constant
            returns (uint count)
    {
        count = proposals[num].voteCount;
    }


}