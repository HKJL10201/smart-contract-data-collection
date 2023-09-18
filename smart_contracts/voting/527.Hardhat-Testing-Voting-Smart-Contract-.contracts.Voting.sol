// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    // Define a Candidate struct
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    // Define an array of candidates
    Candidate[] public candidates;

    // Define a mapping of addresses to boolean values to track if an address has already voted
    mapping(address => bool) public voters;

    // Add a candidate to the list
    function addCandidate(string memory name) public {
        candidates.push(Candidate(name, 0));           // To ensures that every candidate added to the list starts with a vote count of zero
    }

    // Allow a voter to cast their vote for a specific candidate
    function vote(uint256 candidateIndex) public {
        require(candidateIndex >= 0 && candidateIndex < candidates.length, "Invalid candidate index");
        require(!voters[msg.sender], "You have already voted");
        candidates[candidateIndex].voteCount++;
        voters[msg.sender] = true;
    } 

    // Determine the candidate with the highest number of votes
    function getWinner() public view returns (string memory) {
        uint256 highestVoteCount = 0;
        string memory winnerName = "";
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > highestVoteCount) {
                highestVoteCount = candidates[i].voteCount;
                winnerName = candidates[i].name;
            }
        }
        return winnerName;
    }
}
