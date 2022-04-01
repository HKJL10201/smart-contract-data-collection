pragma solidity ^0.4.2;

contract Election {

  // model candidate
  struct Candidate {
    uint id;
    string name;
    uint voteCount;
  }

  // store array of candidates
  mapping(uint => Candidate) public candidates;

  // store accounts that have voted
  mapping(address => bool) public voters;

  uint public candidatesCount;

  // constructor
  function Election() public {
    addCandidate("Jagjot Singh");
    addCandidate("Harjit Kumar");
  }

  function addCandidate(string _name) private {
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }

  function vote(uint _candidateId) public {
    // check if the address has not voted before
    require(!voters[msg.sender]);

    // check that we are voting for the valid candidate
    require(_candidateId > 0 && _candidateId <= candidatesCount);

    // record that voter has voted for this candidate and cannot vote again
    voters[msg.sender] = true;
    // vote the candidate
    candidates[_candidateId].voteCount++;
  }

}
