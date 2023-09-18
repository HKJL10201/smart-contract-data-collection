// SPDX-License-Identifier: MIT
pragma solidity >=0.4.16 <0.9.0;

contract Election {
    string public candidate;

    constructor () public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    mapping(address => bool) public voters;

    mapping(uint => Candidate) public candidates;

    uint public candidateCount;

    event votedEvent (
        uint indexed _candidateId
    );

    function addCandidate (string memory _name) private {
        candidateCount++;
        candidates[candidateCount] = Candidate(candidateCount, _name, 0);
    }

    function vote (uint _candidateId) public {
        require(!voters[msg.sender]);
        require(_candidateId > 0 && _candidateId <= candidateCount);
        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;
        emit votedEvent(_candidateId);
    }
}