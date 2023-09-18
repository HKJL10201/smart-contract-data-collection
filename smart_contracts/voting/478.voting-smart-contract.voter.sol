// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

// You are supposed to complete this assignment by defining appropriate data types
// And working on the code implementation for the various functions/methods in the contract
contract Voting {
    // Define an Appropriate Data Type to Store Candidates
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    
    // Define an Appropriate Data Type to Track If Voter has Already Voted
    mapping(address => bool) public hasVoted;

    // Define an array to store the list of candidates
    Candidate[] public candidates;

    // Adds New Candidate
    function addCandidate(string memory _name) public {
        uint candidateId = candidates.length + 1;
        candidates.push(Candidate(candidateId, _name, 0));
    }

    // Removes Already Added Candidate
    function removeCandidate(uint _candidateId) public {
        require(_candidateId > 0 && _candidateId <= candidates.length, "Invalid candidate ID");
        delete candidates[_candidateId - 1];
    }

    // Retrieves All Candidates for Viewing
    function getAllCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    // Allows Voter to Cast a Vote for a Single Candidate
    function castVote(uint _candidateId) public {
        require(_candidateId > 0 && _candidateId <= candidates.length, "Invalid candidate ID");
        require(!hasVoted[msg.sender], "You have already voted");

        candidates[_candidateId - 1].voteCount++;
        hasVoted[msg.sender] = true;
    }
}
