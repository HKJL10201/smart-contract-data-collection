// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Voting{
    struct Candidate { // Creating a struct to store the details of a Candidate
        string name;
        string party;
        string imageUrl;
    }

    uint256 public CandidateCount;
    mapping (uint256 => Candidate) candidates; // Creating a connection between number of candidates and their details, i.e struct


    address public owner; // Linking this to the constructor function

    mapping (uint256 => uint256) public votes;
    uint256 public totalvotes;

    constructor() {
        owner = msg.sender; 
    }


    function addCandidate(string calldata name, string calldata party, string calldata imageUrl) public { // Creating a function which is used to add the details of a Candidate
        require(owner == msg.sender, "You aren't the owner of contract.");
        CandidateCount++; // Increasing the count of candidates
        Candidate memory person = Candidate({name: name, party: party, imageUrl: imageUrl});
        candidates[CandidateCount] = person; // Storing the value of candidates in an array
    }


    function vote(uint256 id) public {
        require(id > 0, "Candidate doesn't exist");
        require(id <= CandidateCount, "Candidate doesn't exist");
        votes[id]++;    // Increasing the vote count of a candidate 
        totalvotes++; // 
    }



}