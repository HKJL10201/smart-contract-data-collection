pragma solidity ^0.5.0;

contract Election {
     //Model a candidate
     struct Candidate{
         uint id;
         string name;
         uint voteCount;
     }
     //Store candidate
     //Fetch candidate
     mapping(uint => Candidate) public candidates;
     //Store candidate Count
    uint public candidatesCount;

    constructor() public{
        addCandidate("candidate 1");
        addCandidate("candidate 2");
    } 
    function  addCandidate (string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }
}