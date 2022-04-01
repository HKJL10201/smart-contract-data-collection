// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Election {

  // declare candidate variable
  // string public candidate;

  // To store more than one candidate details we use STRUCT
  struct Candidate{
    uint id;
    string name;
    uint voteCount;
  }

  // read and write more than one candidate
  mapping(uint =>Candidate) public candidates;

  // strore candidates count in the contract
  uint public candidatesCount;

  // initialize a constructor
  constructor() public {
    // candidate = "Candidate1";
    // ADDING CANDIDATES INSIDE THE CONSTRUCTOR
    addCandidate("Candidate1");
    addCandidate("Candidate2");
  }

  // FUNTION TO ADD CANDIDATES
  function addCandidate(string memory _name) private{
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }
}
