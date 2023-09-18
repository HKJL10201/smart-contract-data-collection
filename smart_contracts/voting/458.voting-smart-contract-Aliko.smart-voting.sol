// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


// Define an Appropriate Data Type to Store Candidates
contract Voting {
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    Candidate[] public candidates;

    // Define an Appropriate Data Type to Track If Voter has Already Voted

    mapping(address => bool) public hasVoted;

    address public owner;

    constructor(string[] memory candidateNames) {
        owner = msg.sender;
        for (uint256 i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate(i, candidateNames[i], 0));
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner,);
        _;
    }

        // Adds new candidate
    function addCandidate(string memory candidateName) public onlyOwner {
        candidates.push(Candidate(candidates.length, candidateName, 0));
    }


      // Removes Already Added Candidate
    function removeCandidate(uint256 candidateId) public onlyOwner {
        require(candidateId < candidates.length, "Invalid candidate ID");

        for (uint256 i = candidateId; i < candidates.length - 1; i++) {
            candidates[i] = candidates[i + 1];
        }

        candidates.pop();
    }

      // Retrieves All Candidates for Viewing
    function getCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }


       // Allows Voter to Cast a Vote for a Single Candidate
    function castVote(uint256 candidateId) public {
        require(candidateId < candidates.length, "Invalid candidate ID");
        require(!hasVoted[msg.sender], "You have already voted");
        candidates[candidateId].voteCount++;
        hasVoted[msg.sender] = true;
    }

    function getVoteCount(uint256 candidateId) public view returns (uint256) {
        require(candidateId < candidates.length, "Invalid candidate ID");
        return candidates[candidateId].voteCount;
    }

    function getTotalCandidates() public view returns (uint256) {
        return candidates.length;
    }
}
