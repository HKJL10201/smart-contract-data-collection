// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.7.0;

contract Election {
    string public candidate;
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }
    mapping(uint256 => Candidate) public candidates;
    uint256 public candidatesCount;

    constructor() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    mapping(address => bool) public voters;

    function vote(uint256 _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender]);

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;
    }
}
