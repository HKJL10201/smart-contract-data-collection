pragma solidity ^0.5.1;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Store accounts that have voted
    mapping(address => bool) public voters;

    // Store Candidates
    // Fetch Candidates
    mapping(uint => Candidate) public candidates;

    // Store Candidates Count
    uint public candidatesCount;

    // Voted Event
    event votedEvent (
        uint indexed _candidateId
    );
   
    // Constructor
    constructor() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate(string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function voteCast(uint _candidateId) public {
        // Require that they haven't voted before
        require(!voters[msg.sender], "You are already voted!");

        // Require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Not valid Candidate!");

        // Record that voter has voted
        voters[msg.sender] = true;

        // Update candidate vote Count
        candidates[_candidateId].voteCount ++;

        // Trigger voted event
        emit votedEvent(_candidateId);
    }
}