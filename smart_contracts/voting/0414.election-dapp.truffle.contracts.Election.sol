// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

contract Election{
    // Model a candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    // Store candidate 
    // Fetch Candidate
    mapping(uint => Candidate) public candidates;
    // Constructor
    uint public candidateCount;

    constructor() {
        addCandidate("candidate 1");
        addCandidate("candidate 2");
    }

    function addCandidate (string memory __name) private {
        // The number of candidates will be increased by 1
        candidateCount++;
        // Add to the list of candidate with another named candidate
        candidates[candidateCount] = Candidate(candidateCount, __name, 0);
    }
}

// Election.deployed().then(function(instance){app=instance})