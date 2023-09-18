// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title Voting with delegation
contract Ballot {
    struct Voter {
        // voteRightCount is accumulated by delegation
        uint256 voteRightCount;
        // if true, that person already voted
        bool voted;
        // person delegated to
        address delegate;
        // index of the voted proposal
        uint256 vote;
    }
    struct Candidate {
        // short name (up to 32 bytes)
        string name;
        // number of accumulated votes
        uint256 voteCount;
    }
    address public chairperson;
    mapping(address => Voter) public voters;
    Candidate[] public candidates;

    constructor(string[] memory candidateNames) {
        chairperson = msg.sender;
        voters[chairperson].voteRightCount = 1;
        for (uint256 i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate({name: candidateNames[i], voteCount: 0}));
        }
    }

    function giveRightToVote(address voter) external {
        require(
            msg.sender == chairperson,
            "only chairperson can give rights to vote."
        );
        require(!voters[voter].voted, "The voter already voted.");
        require(voters[voter].voteRightCount == 0);
        voters[voter].voteRightCount = 1;
    }

    function delegate(address to) external {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-deligation is disallowed.");
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation.");
        }
        Voter storage delegate_ = voters[to];
        require(delegate_.voteRightCount >= 1);
        sender.voted = true;
        sender.delegate = to;
        if (delegate_.voted)
            candidates[delegate_.vote].voteCount += sender.voteRightCount;
        else delegate_.voteRightCount += sender.voteRightCount;
    }

    function vote(uint256 candidate) external {
        Voter storage sender = voters[msg.sender];
        require(sender.voteRightCount != 0, "Has no right to vote.");
        require(!sender.voted, "Already voted");
        sender.voted = true;
        sender.vote = candidate;
        candidates[candidate].voteCount += sender.voteRightCount;
    }

    function winningCandidate()
        public
        view
        returns (uint256 winningCandidate_)
    {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < candidates.length; p++) {
            if (candidates[p].voteCount > winningVoteCount) {
                winningVoteCount = candidates[p].voteCount;
                winningCandidate_ = p;
            }
        }
    }

    function winnerName() external view returns (string memory winnerName_) {
        winnerName_ = candidates[winningCandidate()].name;
    }
}
