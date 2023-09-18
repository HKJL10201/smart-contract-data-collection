pragma solidity >= 0.4.11 < 0.8.0;

contract Election {
  // Model a candidate
  struct Candidate {
    uint id;
    string name;
    uint votesCount;
  }

  // Store a candidates

  // Fetch Candidate
  mapping(uint => Candidate) public candidates;

  // Store candidates Count
  uint public candidatesCount;

  // Constructor
  constructor () public {
    addCandidate("Candidate 1");
    addCandidate("Candidate 2");
  }

  function addCandidate (string memory _name) private {
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }
}
