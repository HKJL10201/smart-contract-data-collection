pragma solidity ^0.5.0;

contract Election {
    // Read/write candidate
    string public candidate;

    // Constructor
    constructor() public {
        // Add two candidates
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    // Model a Candidate
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    // Store Candidates Count
    uint256 public candidatesCount;

    // Read/write Candidates
    mapping(uint256 => Candidate) public candidates;

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }
}
