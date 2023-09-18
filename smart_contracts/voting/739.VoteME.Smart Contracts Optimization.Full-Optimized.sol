// SPDX-License-Identifier: GPL-3.0
// remove functions
pragma solidity >=0.5.16;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint256 id;
        uint256 voteCount;
        bytes32 name;
        bytes32 party;
    }
 
    // Store accounts that have voted
    mapping(address => bool) public voters;
    // Store and Fetch Candidates
    mapping(uint256 => Candidate) public candidates;
    // Store Candidates Count
    uint256 public candidatesCount;
 
    // voted event
    event votedEvent (
        uint256 indexed _candidateId
    );
 
    constructor () public {
        addCandidate("Ranil Wickremesinghe","United National Party");
        addCandidate("Mahinda Rajapaksha","Sri Lanka Podujana Peramuna");
        addCandidate("Anura Kumara Disanayake","National People's Power");
        addCandidate("Sajith Premadasa","Samagi Jana Balawegaya");
        addCandidate("Maithripala Sirisena","Sri Lanka Freedom Party");
        addCandidate("NOTA","None of the above");
    }
 
    function addCandidate (bytes32 name,bytes32 party) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, 0, name,party);
    }
    
    function vote (uint256 _candidateId) public {
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
}