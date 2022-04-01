pragma solidity ^0.4.0;
contract Election{
  // Model a Candidate
struct Candidate {
    uint id;
    string name;
    uint voteCount;
}
  //stroe candidate
  //read candidate
  //Constructor

  mapping(uint => Candidate) public candidates;
  mapping(address => bool) public voters;

  uint public candidatesCount;

  string public candidate;
  constructor() public{
    addCandidate("Candidate 1");
    addCandidate("Candidate 2");
  }
  event votedEvent (
    uint indexed _candidateId
);

  function addCandidate (string _name) private{
    candidatesCount ++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }
  function vote (uint _candidateId) public {
    // require that they haven't voted before
    require(!voters[msg.sender]);

    // require a valid candidate
    require(_candidateId > 0 && _candidateId <= candidatesCount);

    // record that voter has voted
    voters[msg.sender] = true;

    // update candidate vote Count
    candidates[_candidateId].voteCount ++;

    emit votedEvent(_candidateId);
}

}
