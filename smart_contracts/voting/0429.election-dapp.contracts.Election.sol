pragma solidity ^0.4.23;

contract Election {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    mapping(uint => Candidate) public candidateList;
    uint public candidateCount;

    constructor() public {
        addCandidate('Candidate 1');
        addCandidate('Candidate 2');
    }

    function addCandidate(string _name) private {
        candidateCount++;
        candidateList[candidateCount] = Candidate(candidateCount, _name, 0);
    }
}
