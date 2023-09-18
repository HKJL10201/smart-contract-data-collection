// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VoteChain {
    struct Candidate {
        uint id; 
        string name;
        uint voteCount; 
    }

    struct Session {
        uint id;
        string topic; 
        uint startTime; 
        uint endTime; 
        bool active; 
        mapping(uint => Candidate) candidates;
        uint numCandidates; 
        mapping(address => bool) voters; 
    }

    
    mapping(uint => Session) public sessions;

    uint public nextSessionId;

    
    event SessionCreated(uint sessionId, string topic, uint startTime, uint endTime);

    
    event VoteCasted(uint sessionId, uint candidateId, address voter);

    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier validSession(uint sessionId) {
        require(sessions[sessionId].active, "Invalid or inactive session.");
        _;
    }

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // A function to create a new voting session with a given topic and a list of candidate names
    function createSession(string memory _topic, string[] memory _candidateNames) public onlyOwner {
        require(_candidateNames.length > 1, "At least two candidates are required.");
        uint sessionId = nextSessionId; 
        nextSessionId++; 
        Session storage session = sessions[sessionId];
        session.id = sessionId; 
        session.topic = _topic; 
        session.startTime = block.timestamp; 
        session.endTime = block.timestamp + 24 hours;
        session.active = true; 

        for (uint i = 0; i < _candidateNames.length; i++) { 
            uint candidateId = i + 1; 
            Candidate storage candidate = session.candidates[candidateId]; 
            candidate.id = candidateId; 
            candidate.name = _candidateNames[i]; 
            candidate.voteCount = 0; 
            session.numCandidates++; 
        }

        emit SessionCreated(sessionId, _topic, session.startTime, session.endTime); 
    }

    // A function to cast a vote for a given candidate in a given session
    function castVote(uint sessionId, uint candidateId) public validSession(sessionId) {
        Session storage session = sessions[sessionId]; 

        require(!session.voters[msg.sender], "You have already voted in this session.");

        require(candidateId > 0 && candidateId <= session.numCandidates, "Invalid candidate id.");

        Candidate storage candidate = session.candidates[candidateId]; 

        candidate.voteCount++; 

        session.voters[msg.sender] = true; 

        emit VoteCasted(sessionId, candidateId, msg.sender); 

    }

}