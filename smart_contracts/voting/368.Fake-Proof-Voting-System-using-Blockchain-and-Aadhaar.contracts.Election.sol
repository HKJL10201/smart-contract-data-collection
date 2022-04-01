// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Election{
    // sturct candidate
    // candidate count
    // mapping candidate
    struct Candidate{
        uint id;
        string name;
        uint votecount;
    }

    uint public candidatesCount;

    mapping(uint=>Candidate) public candidates;
    mapping(address=>bool) public voteornot;

    event electionUpdate(uint id,string name,uint votecount);

    constructor(){
        // the code that we want to initate
        addCandidate("EDAPPADI K. PALANISWAMI");
        addCandidate("STALIN");
        addCandidate("SEEMAN");
        addCandidate("VALLA DURAI");
        addCandidate("VIMAL SAI PRASAD");
        addCandidate("GP MUTHU");
    }
    // add Candidates
    function addCandidate (string memory name) private{
        candidatesCount++;
        candidates[candidatesCount]=Candidate(candidatesCount,name,0);
    }

    // Vote Function

    function vote(uint _id) public{
        // the person has vote again 
        require(!voteornot[msg.sender],'You have voted fot the participant');
        require(candidates[_id].id!=0,'The ID Doesnt Exist');
        require(_id>0 && _id<= candidatesCount++);

        candidates[_id].votecount++;
        // the id that the person has input is available
        voteornot[msg.sender]=true;
        emit electionUpdate(_id,candidates[_id].name,candidates[_id].votecount);
    }
}