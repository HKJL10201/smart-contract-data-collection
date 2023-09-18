// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Election {
  struct Candidate {
    uint id;
    string name;
    uint voteCount;
  }

  mapping (uint => Candidate) public candidates;

  uint public candidatesCount;

  constructor() public  {
    addCandidate("tashi");
  }

  function addCandidate (string memory _name) private {
    candidatesCount ++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }

  mapping (address => bool) public voters;

  function vote(uint _candidateId) public {
    require (!voters[msg.sender]);
    require (_candidateId > 0 && _candidateId <= candidatesCount);
    voters[msg.sender] = true;
    candidates[_candidateId].voteCount++;
  }
}
