// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.2;

contract Voting {
    mapping(uint256 => Candidate) public candidates;
    uint256 public candidatesCount;

    struct Candidate {
        uint256 id;
        string name;
        uint256 votes;
    }

    constructor() {
        candidatesCount = 0;
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }
}
