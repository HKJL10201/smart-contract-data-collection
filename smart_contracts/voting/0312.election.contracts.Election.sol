pragma solidity ^0.4.24;

contract Election {

  struct Candidate {
    uint id;
    string name;
    uint voteCount;
  }

  mapping(uint => Candidate) public candidates;
  uint public candidatesCount;
  mapping(address => bool) public voters;

  event votedEvent(uint indexed _candidateId);

  constructor() public {
    addCandidate("Candidate 1");
    addCandidate("Candidate 2");
  }
  function addCandidate(string _name) private {
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }

  function vote(uint _candidateId) public {
    require(voters[msg.sender] == false, "already voted");
    require(_candidateId > 0 && _candidateId <= candidatesCount, "invalid candidate");
    voters[msg.sender] = true;
    candidates[_candidateId].voteCount++;
    emit votedEvent(_candidateId);
  }
}