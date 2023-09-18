// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract Voting {
    // Define an Appropriate Data Type to Store Candidates
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    mapping(address => bool) public voters;
    Candidate[] public candidates;
    uint public candidateCount;

    // Adds New Candidate
    function addCandidate(string memory _name) public {
        candidateCount++;
        candidates.push(Candidate(candidateCount, _name, 0));
    }

    // Removes Already Added Candidate
    function removeCandidate(uint _candidateId) public {
        require(_candidateId > 0 && _candidateId <= candidateCount, "Invalid candidate ID");
        require(candidates[_candidateId - 1].voteCount == 0, "Cannot remove candidate with votes");
        
        candidateCount--;
        candidates[_candidateId - 1] = candidates[candidateCount];
        candidates.pop();
    }

    // Retrieves All Candidates for Viewing
    function getAllCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    // Allows Voter to Cast a Vote for a Single Candidate
    function castVote(uint _candidateId) public {
        require(_candidateId > 0 && _candidateId <= candidateCount, "Invalid candidate ID");
        require(!voters[msg.sender], "You have already voted");
        
        voters[msg.sender] = true;
        candidates[_candidateId - 1].voteCount++;
    }
}
