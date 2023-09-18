pragma solidity ^0.4.24;

contract Voting {
     
    // Model a candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Read/write Candidates
    mapping (uint => Candidate) public candidates;

    // Store accounts that have voted
    mapping(address => bool) public voters;

    // Store Candidate Count
    uint public candidatesCount;

    event votedEvent(
        uint indexed _candidateId
    );

    // Contructor
    constructor () public {
        addCandidate("hainv");
    }

    // Add Candidate
    function addCandidate(string _name) public {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount,_name, 0);
    }

    // Vote
    function vote(uint _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender]);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        voters[msg.sender] = true;

        // update candidate vote count
        candidates[_candidateId].voteCount ++;

        // trigger voted event
        // emit votedEvent(_candidateId);
    }
}