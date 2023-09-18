pragma solidity ^0.5.0;

contract Election {
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }
    uint256 public candidatesCount;
    mapping(uint256 => Candidate) public candidates;
    mapping(address => bool) public voters;

    constructor() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint256 _candidateId) public {
        require(
            _candidateId <= candidatesCount && _candidateId > 0,
            "Invalid candidate"
        );
        require(!voters[msg.sender], "Vote must not have voted before.");
        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;
    }
}
