// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Election {

  // model a candidate
  struct Candidate {
    uint id;
    string name;
    uint voteCount;
  }

  // store accounts of voters
  mapping (address => bool) public voters;
  // read/write Candidates
  mapping (uint => Candidate) public candidates;
  // store Candidates count
  uint public candidatesCount;

  event votedEvent(
    uint indexed _candidateId
  );

  // constructor
  constructor() public {
    addCandidate("Candidate 1");
    addCandidate("Candidate 2");
  }

  function addCandidate(string memory _name) private {
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }

  function vote(uint _candidateId) public {
    // require that they haven't voted before
    require(!voters[msg.sender]);

    // require a valid candidate
    require(_candidateId > 0 && _candidateId <= candidatesCount, "Please enter a valid candidate ID");

    // record that voter has voted
    voters[msg.sender] = true;

    // update candidate vote count
    candidates[_candidateId].voteCount++;

    // trigger event
    emit votedEvent(_candidateId);
  }
}
