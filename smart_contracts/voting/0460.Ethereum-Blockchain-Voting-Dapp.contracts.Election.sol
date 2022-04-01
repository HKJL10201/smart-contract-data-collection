pragma solidity ^0.4.24;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Store Candidates

    // Fetch Candidate
    mapping(uint => Candidate) public candidates;

    // Store Candidates Count
    uint public candidatesCount=0;
     
    constructor() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
        voteCandidate(1);
        voteCandidate(1);
        voteCandidate(1);
        voteCandidate(2);
        voteCandidate(2);
    }

    function addCandidate(string _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function voteCandidate(uint id) public {
        if(id <= candidatesCount){
            candidates[id].voteCount++;
        }
    }

}