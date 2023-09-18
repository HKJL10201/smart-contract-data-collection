// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract Voting {
    // Define an Appropriate Data Type to Store Candidates
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    // Define an Appropriate Data Type to Track If Voter has Already Voted
    mapping(address => bool) public voters;

    // Array to store candidates
    Candidate[] private candidates;

    // Adds New Candidate
    function addCandidate(string memory _name) public {
        for (uint i = 0; i < candidates.length; i++) {
            if (keccak256(abi.encodePacked(candidates[i].name)) == keccak256(abi.encodePacked(_name))) {
                // Value is in the array, revert the transaction
                revert("Value is already in the array");
            }
            else{
              candidates.push(Candidate(_name, 0));
            }
        }
        
       
    }

    // Removes Already Added Candidate
    function removeCandidate(uint256 _index) public {
        require(_index < candidates.length, "Invalid candidate index");
        require(candidates[_index].voteCount == 0, "Cannot remove candidate with votes");

        // Move the last candidate to the index being removed and then reduce the array size
        candidates[_index] = candidates[candidates.length - 1];
        candidates.pop();
    }

    // Retrieves All Candidates for Viewing
    function getAllCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    // Allows Voter to Cast a Vote for a Single Candidate
    function castVote(uint256 _candidateIndex) public {
        require(_candidateIndex < candidates.length, "Invalid candidate index");
        require(!voters[msg.sender], "You've already voted");

        candidates[_candidateIndex].voteCount++;
        voters[msg.sender] = true;
    }
}
