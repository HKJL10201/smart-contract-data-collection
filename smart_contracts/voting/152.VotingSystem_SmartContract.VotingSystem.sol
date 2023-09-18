//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Election {
    // Model of a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        string details;
        string election_id;
    }

     // Store accounts that have voted
    mapping(address => bool) public voters;

    // Store Candidates
    // Fetch Candidate
    mapping(uint => Candidate) public candidates;

    // Store Candidates Count
    uint public candidatesCount;

    constructor() {}

    // voted event
    event votedEvent(
        uint indexed _candidateId
    );

    // function to add a candidate
    function addCandidate(string memory _name, string memory _details, string memory _election_id) public {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0, _details, _election_id);
    }

    function vote(uint _candidateId) public {

        // require that they haven't voted before
        require(!voters[msg.sender]);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = true;

         // update candidate vote Count
        candidates[_candidateId].voteCount++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }

}
