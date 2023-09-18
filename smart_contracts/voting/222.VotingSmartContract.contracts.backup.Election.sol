pragma solidity ^0.4.11;

contract Election {
    //candidate model
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Store candidate
    mapping(uint => Candidate) public candidates;
    // store candidate count
    uint public candidatesCount;

    function addCandidate (string _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function Election () public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }
}
