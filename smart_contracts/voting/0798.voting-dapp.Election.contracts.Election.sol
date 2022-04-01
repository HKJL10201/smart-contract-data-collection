// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Election {

  struct Candidate {
    uint id;
    string name;
    uint voteCount;
  }

  uint public candidateCount = 0;
  mapping (uint => Candidate) public candidates;

  constructor () public {
    addCandidate("Alice");
    addCandidate("Bob");
  }

  function addCandidate(string memory _name) public {
    // candidateCount++;
    candidates[candidateCount++] = Candidate(candidateCount, _name, 0);
  }


}
