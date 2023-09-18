// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <8.10.0;

contract Election {

struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

     event votedEvent (
        uint indexed _candidateId
    );

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;

    uint public candidatesCount = 0;
    
    function addCandidate (string memory _name) public {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function getCandidate (uint i) public view returns(string memory){
    return candidates[i].name;
    }

    function getCandidateCount (uint i) public view returns(uint){
    return candidates[i].voteCount;
    }

    function vote (uint _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender]);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;
        // trigger voted event
    emit votedEvent(_candidateId);
    }

    constructor() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    

}