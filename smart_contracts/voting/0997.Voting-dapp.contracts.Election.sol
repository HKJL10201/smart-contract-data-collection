// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Election {
    address public admin;                   
    uint public startTime;
    uint public votingDuration = 3 days;    
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    // Store accounts that have voted
    mapping(address => bool) public votedornot;
    // Store Candidates
    // Fetch Candidate
    mapping(uint => Candidate) public candidates;
    // Store Candidates Count
    uint public candidatesCount;

    // voted event
    event electionupdates(
        uint indexed _candidateId
    );

    constructor() {
        admin = msg.sender;
        startTime = block.timestamp;
    }

    function addCandidate (string memory name) public {
        require(block.timestamp <= startTime + votingDuration);
        require(msg.sender == admin);
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, name , 0);
    }

    function vote (uint _candidateId) public{
        require(block.timestamp <= startTime + votingDuration);
        // require that they haven't voted before
        require(!votedornot[msg.sender]);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        // record that voter has voted
        votedornot[msg.sender] = true;

        // trigger voted event
        emit electionupdates(_candidateId);
    }
}