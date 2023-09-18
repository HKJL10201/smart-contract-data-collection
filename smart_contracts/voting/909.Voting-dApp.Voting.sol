// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Voting{
    struct Candidate { // This struct refers to the individual data of any particular candidate, it will be useful for linking everything in future
        string name;
        string party;
        string imageUrl;
    }

    uint256 public CandidateCount;
    mapping (uint256 => Candidate) candidates; // Creating a connection between number of candidates and their details, i.e struct


    address public owner; // Linking this to the constructor function

    mapping (uint256 => uint256) public votes;
    uint256 public totalvotes;

    constructor() { // constructor is a special type of function that is used to initialize the state variables of a contract when it is deployed. It is executed only once during the contract deployment and cannot be called again afterwards. The constructor has the same name as the contract and is declared using the constructor keyword
        owner = msg.sender; // The constructor function assigns the address of the contract deployer (msg.sender) to the owner variable.
    }


    function addCandidate(string calldata name, string calldata party, string calldata imageUrl) public { // Creating a function which is used to add the details of a Candidate
        require(owner == msg.sender, "You aren't the owner of contract.");
        CandidateCount++; // Increasing the count of candidates
        Candidate memory person = Candidate({name: name, party: party, imageUrl: imageUrl});
        candidates[CandidateCount] = person; // Storing the value of candidates in an array
    }


    function vote(uint256 id) public {
        require(id > 0, "Candidate doesn't exist"); // if I try to vote for candidate at index 0 or index 999 which doesn’t even exists, so we need to make sure that the candidate exists, we can do this with require statements.
        require(id <= CandidateCount, "Candidate doesn't exist");
        votes[id]++; // we are taking the index of the candidate as an input and just increasing his votes in the mapping and also incrementing total votes.
        totalvotes++; // 
    }



}