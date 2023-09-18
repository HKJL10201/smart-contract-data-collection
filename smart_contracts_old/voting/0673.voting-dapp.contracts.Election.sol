pragma solidity >=0.4.22 <0.8.0;

contract Election {
    // Store Candidate Name
    // Read Candidate Name
    string public candidate;
    // Constructor
    constructor() public {
        // non-underscored variable represents a "state variable"
        // which is accessible inside of the contract, and represents
        // data that belongs to the entire contract 
        candidate = "Candidate 1";

    }
}