pragma solidity ^0.5.16;

contract Election {
    
    // Municipal Candidate Model
    struct Candidate {
        uint16 voteCount;
        uint id;
        string name;
    }

    //  Read / Write 
    mapping(uint => Candidate) public candidates;
    uint16 public candidatesCount;

    // Constructor
    constructor () public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }


    function addCandidate(string memory _name) private {
        // TODO add requirement to keep inputs clean
        // TODO Modify this with OpenZepplin incrimental counter
        candidatesCount++;
        // TODO ALter this so the candidate ID is not an incremental count number, but rather a real unique id.
        candidates[candidatesCount] = Candidate(0, candidatesCount, _name);

    }
    
}