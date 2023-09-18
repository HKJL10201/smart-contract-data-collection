// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

contract Election {
    //Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    //Store accounts that have voted
    mapping(address => bool) public voters;
    //Store Candidate
    //Fetch Candidate
    mapping(uint => Candidate) public candidates;
    //Store Candidates Count
    uint public candidatesCount;

    event votedEvent(
        uint indexed _candidateId
    );
    //Constructor
    constructor() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }
    function addCandidate(string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint _candidateId) public {
        //Require that they haven't voted before
        require(!voters[msg.sender]);
        //Require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        //Record that voter has voted
        voters[msg.sender] = true;
        //Update candidate vote count
        candidates[_candidateId].voteCount ++;
        //Trigger voted event
        emit votedEvent(_candidateId);
    }
}