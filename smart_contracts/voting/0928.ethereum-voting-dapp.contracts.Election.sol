pragma solidity ^0.5.0;

contract Election {

  //model a candidate
  struct Candidate {
    uint sid;
    string name;
    uint voteCount;
  }

  //Read/Write candidates
  mapping(uint => Candidate) public candidates;
  //store accounts that have voted
  mapping(address => bool) public voters;

  //store candidates count
  uint public candidatesCount;

  //constructor
  constructor() public {
    addCandidate("Candidate 1");
    addCandidate("Candidate 2");
  }

  //private function (can only be called inside the contract)
  function addCandidate (string memory _name) private {
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }

  function vote(uint _candidateId) public {
    //retuire that they haven't voted before
    require(!voters[msg.sender]);

    //retuire a valid candidate
    require(_candidateId > 0 && _candidateId <= candidatesCount);

    //record that voter has voted
    voters[msg.sender] = true;

    //update candidate vote count
    candidates[_candidateId].voteCount ++;

    //trigger voted event
    emit votedEvent(_candidateId);
  }

  event votedEvent (
    uint indexed _candidateId
  );


}
