pragma solidity 0.5.8;

contract Election {

  //model a candidate
  struct Candidate {
    uint id;
    string name;
    uint voteCount;
  }

  //store candidates
  //key is id here
  mapping(uint => Candidate) public candidates; //fetch candidates. public: auto getter function

  //store acc that have voted
  mapping(uint => bool) public voters;

  //store candidates count
  uint public candidatesCount;

  event votedEvent (
    uint indexed _candidateId;
  );

  constructor () public {
    addCandidate("Candidate 1");
    addCandidate("Candidate 2");
  }

  function addCandidate (string memory _name) private {
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }

  function vote(uint _candidateId) public {
    //reuqire they havn't voted before
    require(!voters[msg.sender]);
    //require a valid candidate
    require(_candidateId > 0 && _candidateId <= candidatesCount);

    voters[msg.sender] = true;
    candidates[_candidateId].voteCount++;

    //trigger event
    votedEvent(_candidateId);
  }
}