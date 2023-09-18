pragma solidity 0.5.16;

contract Election {
    // Read/write candidate
    string public candidate;

    // Constructor
    constructor() public {
        //candidate = "Candidate 1";
        addCandidate("Akansha");
        addCandidate("Neha");
    }
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    // Read/write Candidates
    mapping(uint => Candidate) public candidates;
        uint public candidatesCount;
    function addCandidate (string memory _name) private{
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }
}