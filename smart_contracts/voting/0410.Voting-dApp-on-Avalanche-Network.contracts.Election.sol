// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Election {
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    address public owner;

    mapping(uint256 => Candidate) public candidates;
    mapping(address => bool) public voters;

    uint256 public candidataCount;

    constructor() {
        owner = msg.sender;
        addCandidate("Ryle");
        addCandidate("Max");
    }

    function addCandidate(string memory _name) public{
        require(msg.sender == owner, "Only owner can add candidates");
        candidataCount++;
        candidates[candidataCount] = Candidate(candidataCount, _name, 0);
    }

    function vote(uint256 _candidateId) public {
        require(!voters[msg.sender], "You have already voted");
        require(
            _candidateId <= candidataCount && _candidateId >= 1,
            "Invalid candidate Id"
        );
        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;
    }
}
