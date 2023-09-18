pragma solidity 0.5.8;

contract Election {
    // read/write candidate
    string public candidate;

    // declare data model for candidates
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    } 

    // constructor
    constructor() public {
        candidate = "Candidate 1";
    }

    mapping(uint => Candidate) public candidates;
}