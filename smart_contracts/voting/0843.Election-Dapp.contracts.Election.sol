pragma solidity ^0.8.10;

contract Election {
  struct Candidate {
    uint256 id;
    string name;
    uint256 voteCount;
  }

  mapping(uint256 => Candidate) public candidates;

  uint256 public candidatesCount;

  function addCandidate(string memory _name) private {
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }

  mapping(address => bool) public voters;

  event Vote(address, uint);

  function vote (uint _candidateId) public {
    // require that they haven't voted before
    require(!voters[msg.sender]);

    // require a valid candidate
    require(_candidateId > 0 && _candidateId <= candidatesCount);

    // record that voter has voted
    voters[msg.sender] = true;

    // update candidate vote Count
    candidates[_candidateId].voteCount ++;

    emit Vote(msg.sender, _candidateId);
  }

  constructor() {
    addCandidate("Donald Trump");
    addCandidate("Joe Biden");
    addCandidate("Shahnur");
  }
}
