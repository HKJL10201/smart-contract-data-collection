pragma solidity ^0.4.11;

contract Election {
    // Model a candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Store accoutns that have voted
    mapping(address => bool) public voters;
    // Store candidates
    // Fetch candidate
    mapping(uint => Candidate) public candidates;
    // Store candidates count
    uint public candidatesCount;

    event votedEvent(
        uint indexed _candidateId
    );

    function Election() public {
        addCandidate("Donald Trump");
        addCandidate("Hillary Clinton");
    }

    function addCandidate(string _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint _candidateId) public {
        // Require that address has not voted before 
        require(!voters[msg.sender]);
        // Require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        // Record that the voter has voted
        voters[msg.sender] = true;
        // Update candidate vote count
        candidates[_candidateId].voteCount++; 
        // Trigger Voted Event
        emit votedEvent(_candidateId);
    }
}