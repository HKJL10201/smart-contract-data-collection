pragma solidity >=0.5.0 <0.7.0;

contract Election {

    // Voted event
    event votedEvent(uint indexed _candidateId);

    // Model a candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Store candidates
    // Fetch candidate
    mapping (uint => Candidate) public candidates;

    // Store accounts that have voted
    mapping (address => bool) public voters;

    // Store candidate count
    uint public candidatesCount;

    // Constructor
    constructor () public {
        _addCandidate("Candidate 1");
        _addCandidate("Candidate 2");
    }

    function _addCandidate (string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint _candidateId) public {
        // require that voter hasn't voted before
        require(voters[msg.sender] == false, "Voter has already voted!");

        // require that candidateId is valid
        require(_candidateId > 0 && _candidateId <= candidatesCount, "");

        // Update candidate vote Count
        candidates[_candidateId].voteCount++;

        // record that voter has voted
        voters[msg.sender] = true;

        // Trigger the event
        emit votedEvent(_candidateId);
    }
}