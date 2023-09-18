// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
contract Voting {
 
    // It will represent a single voter.
    struct Voter {
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted Candidate 
    }
       enum ELECTION_STATE{
        OPEN,CLOSED
    }
    string public winnerName;
    ELECTION_STATE public election_state;
    // This is a type for a single Candidate.
    struct Candidate {
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;

    // A dynamically-sized array of `Candidate` structs.
    Candidate[] public candidates;

    
    constructor(string[] memory candidateNames) {
        chairperson = msg.sender;
        election_state=ELECTION_STATE.OPEN;
        for (uint i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate({
                name: candidateNames[i],
                voteCount: 0
            }));
        }
    }

    
    /// Give your vote
    function vote(uint candidate) public {
        Voter storage sender = voters[msg.sender];
        require(election_state==ELECTION_STATE.OPEN, "voting closed.");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = candidate;

      
        candidates[candidate].voteCount += 1;
    }

 
    function winningCandidate() public view
            returns (uint winningCandidate_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < candidates.length; p++) {
            if (candidates[p].voteCount > winningVoteCount) {
                winningVoteCount = candidates[p].voteCount;
                winningCandidate_ = p;
            }
        }
    }

    function getWinnerName() public 
    {
        election_state=ELECTION_STATE.CLOSED;
        winnerName = candidates[winningCandidate()].name;
    }
}