// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    // Store accounts that have voted
    mapping(address => bool) public voters;

    // Store Candidates
    mapping(uint256 => Candidate) public candidates;

    // Fetch Candidate

    // Store Candidates Count
    uint256 public candidatesCount;

    // Voted event
    event votedEvent(uint256 indexed _candidateId);

    constructor() public {
        addCandidate("Buhari");
        addCandidate("Atiku");
    }

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

        // Update candidate vote Count
        candidates[_candidateId].voteCount++;

        // Trigger voted event
        emit votedEvent(_candidateId);
    }
}
