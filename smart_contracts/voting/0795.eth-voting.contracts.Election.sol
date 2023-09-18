pragma solidity ^0.5.0;

contract Election {
    string public candidate;

    mapping(address => bool) public voters;

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    mapping(uint => Candidate) public candidates;

    uint public candidatesCount;

    event votedEvent (
        uint indexed _candidateId
    );

    constructor() public {
        addCandidate("Suresh");
        addCandidate("Ramesh");
    }

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint _candidateId) public {
        require(voters[msg.sender] != true, "voter has already voted");
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid Candidate");

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;

        emit votedEvent(_candidateId);
    }
}

