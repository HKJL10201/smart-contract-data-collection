pragma solidity ^0.5.1;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Read/write Candidates
    mapping(uint => Candidate) public candidates;

    // Store accounts that have voted
    mapping(address => bool) public voters;

    // Store Candidates Count
    uint public candidatesCount;
     
    event votedEvent (
        uint indexed _candidateId
    );


    // Constructor
    constructor () public {
        addCandidate("Pakistan Tehreek-e-Insaaf");
        addCandidate("Pakistan Muslim League (N)");
        addCandidate("Pakistan People Party");
    }

    function addCandidate (string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender], 'User alraedy voted');

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount, 'User is not valid');

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }
}