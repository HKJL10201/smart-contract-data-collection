// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract Election{

    struct Candidate{
        uint id;
        string name;
        uint votes;
    }

    uint public candidatesCount;

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public votedornot;


    event electionupdate(uint indexed _candidateId);

    constructor(){
        addCandidate("Trump");
        addCandidate("Biden");
    }

    function addCandidate(string memory name) private{
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount,name,0);
    }

    function Vote(uint _candidateId) public{
        require(!votedornot[msg.sender]);
        require(candidates[_candidateId].id != 0);

        candidates[_candidateId].votes+=1;

        votedornot[msg.sender] = true;
        emit electionupdate(_candidateId);
    }
}