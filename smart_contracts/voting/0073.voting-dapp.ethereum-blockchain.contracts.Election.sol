// solium-disable linebreak-style
pragma solidity ^0.4.24;

contract Election {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    struct Voters {
        bool voted;
        address voterId;
    }

    // Map of candidates
    mapping(uint => Candidate) public candidates;
    // map of voters who have voted
    mapping(uint => Voters) public voters;
    // storing count of candidates
    uint public candidatesCount;

    event votedEvent(
        uint indexed _candidateId
    );

    constructor() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
        addCandidate("Candidate 3");
    }

    function addCandidate (string _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint _candidateId, uint _aadhar) public {
        // require that they haven't voted before
        require(!voters[_aadhar].voted, "Already Voted");

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid Candidate");
    
        voters[_aadhar].voted = true;
        voters[_aadhar].voterId = msg.sender;
        
        candidates[_candidateId].voteCount++;

        emit votedEvent(_candidateId);
    }
}