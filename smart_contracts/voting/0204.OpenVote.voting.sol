// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Voting {
    address private immutable owner;
    uint private conclude;
    uint public candidatesCount;
    uint public voteTotal;
    uint public winnerId;

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) private voters;
    mapping(address => bool) private rights;

    constructor() {
        owner = msg.sender;
    }

    function setVoters(address addr) public {
        require(msg.sender == owner, "Only the contract creator can set the voters");
        rights[addr] = true;
    }

    function addCandidate(string memory name) public {
        require(msg.sender == owner, "Only the contract creator can set the candidates");
        require(voteTotal == 0, "Cannot submit candidate after voting started");
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, name, 0);
    }

    function vote(uint candidateId) public {
        require(rights[msg.sender], "Voter doesn't have the rights to vote");
        require(msg.sender != owner, "The contract creator cannot participate in the voting");
        require(!voters[msg.sender], "Vote already cast from this address");
        require(candidateId > 0 && candidateId <= candidatesCount, "Invalid candidate ID");
        require(candidatesCount >= 2, "Must be at least 2 candidates before votes can be cast");
        require(conclude == 0, "Voting concluded");
        voters[msg.sender] = true;
        candidates[candidateId].voteCount++;
        voteTotal++;
    }

    function concludeVoting() public {
        require(msg.sender == owner, "Only the contract creator can conclude the voting");
        uint maxVote = 0;
        for(uint i=1; i<=candidatesCount; i++) {
            if(candidates[i].voteCount > maxVote) {
                winnerId = i;
                maxVote = candidates[i].voteCount;
            }
        }
        conclude += 1;
    }


    function returnWinner()public view returns (string memory winner) {
        return(candidates[winnerId].name);
    }

    function showName(uint n) public view returns (string memory name) {
         return(candidates[n].name);
    }
}