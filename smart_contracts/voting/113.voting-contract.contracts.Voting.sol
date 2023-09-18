// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract Voting {
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    mapping(uint256 => Candidate) public candidates;
    uint256 public candidateCount;

    mapping(address => bool) public hasVoted;

    constructor() {
        // Initialize candidate count
        candidateCount = 0;
    }

    // Adds New Candidate
    function addCandidate(string memory _name) public {
        candidateCount++;
        candidates[candidateCount] = Candidate(candidateCount, _name, 0);
    }

    // Removes Already Added Candidate
    function removeCandidate(uint256 _candidateId) public {
        require(_candidateId > 0 && _candidateId <= candidateCount, "Invalid candidate ID");
        delete candidates[_candidateId];
    }

    // Retrieves All Candidates for Viewing
    function getAllCandidates() public view returns (Candidate[] memory) {
        Candidate[] memory allCandidates = new Candidate[](candidateCount);
        for (uint256 i = 1; i <= candidateCount; i++) {
            allCandidates[i - 1] = candidates[i];
        }
        return allCandidates;
    }

    // Allows Voter to Cast a Vote for a Single Candidate
    function castVote(uint256 _candidateId) public {
        require(_candidateId > 0 && _candidateId <= candidateCount, "Invalid candidate ID");
        require(!hasVoted[msg.sender], "Already voted");

        candidates[_candidateId].voteCount++;
        hasVoted[msg.sender] = true;
    }
}
