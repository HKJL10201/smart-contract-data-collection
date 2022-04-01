pragma solidity ^0.5.0;
//pragma solidity 0.5.8;

contract Election {
    
    //Read/write candidateto
    string public candidate;

    //constructor
    //function Election () public {
    constructor() public {
        candidate = "Candidate 1";
    }
}