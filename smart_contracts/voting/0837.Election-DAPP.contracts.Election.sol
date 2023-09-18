pragma solidity ^0.4.24;

contract Election {
  	// Model a candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    // Store candidates
    // Fetch candidates
    mapping(uint => Candidate) public candidates;
    // Store candidates count
    uint public candidatesCount;
  	// Constructor
    constructor() public{
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate(string _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }
}