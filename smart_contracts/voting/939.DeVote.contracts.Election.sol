pragma solidity ^0.5.0;

contract Election {
    // Candidates structure
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    // Store candidates
    mapping(uint256 => Candidate) public candidates;

    // Store accounts that have already voted
    mapping(address => bool) public voters;

    // Store candidates count
    uint256 public candidatesCount;

    event votedEvent(uint256 indexed _candidateId);

    // Constructor
    constructor() public {
        addCandidate("AAP");
        addCandidate("BJP");
        addCandidate("BSP");
        addCandidate("INC");
    }

    // Add a candidate
    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint256 _candidateId) public {
        // Require that they haven't voted before
        require(!voters[msg.sender]);

        // Require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // Record that voter has voted
        voters[msg.sender] = true;

        // Update candidate vote count
        candidates[_candidateId].voteCount++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }
}
