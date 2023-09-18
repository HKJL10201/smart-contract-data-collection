pragma solidity ^0.5.16;

contract Election {
    // Candidate Model
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Store accounts that have voted
    mapping(address => bool) public voters;

    // Fetch candidates
    mapping(uint => Candidate) public candidates;

    // Store count of how many candidates there are
    uint public candidatesCount;

    event votedEvent (
        uint indexed _candidateId
    );

    constructor () public {
        addCandidate("Michael Jordan");
        addCandidate("Lebron James");
    }

    function addCandidate (string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint _candidateId) public {
        // require voter hasn't voted before
        require(!voters[msg.sender]);

        // require that candidate is valid
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // set voter's status to true meaning that voter has voted 
        voters[msg.sender] = true;

        // update candidate vote count
        candidates[_candidateId].voteCount ++;

        emit votedEvent(_candidateId);
    }
}