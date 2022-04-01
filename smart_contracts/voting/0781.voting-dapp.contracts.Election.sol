// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Election {

    // Model the cadidates
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Store Candidates
    mapping(uint => Candidate) public candidates;

    // Store Candidate Count so we can determine how many there actually are in our mapping object
    uint public candidatesCount;

    string public candidate;

    constructor() {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");

    }

    // Define an addCandidates function
    function addCandidate(string memory _name) private {
        // Increment the Candidates count
        candidatesCount ++;

        // Set the new candidate at the newly incremented candidate count
        // within our mapping to an instantiation of the Candidate struct 
        // with the new parameters of candidatesCount as the id, _name passed
        // from the addCandidate argument as the candidates name, and 0
        // representing the candidates initial voteCount
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }
}