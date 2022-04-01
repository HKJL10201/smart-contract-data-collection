pragma solidity ^0.5.0;

contract Election {
  // Model candidate
  struct Candidate {
    uint id;
    string name;
    uint voteCount;
  }
  // Store candidate
  mapping(address => bool) public voters;
  // fetch candidate
  mapping(uint => Candidate) public candidates;
  // store candidate
  uint public candidatesCount;

   // voted event
  event votedEvent (
      uint indexed _candidateId
  );

  constructor () public {
    addCandidate("Candidate 1");
    addCandidate("Candidate 2");
  }

  function addCandidate (string memory _name) private {
    candidatesCount ++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }

  function vote (uint _candidateId) public {
      // require that they haven't voted before
      require(
        !voters[msg.sender],
        "Sender not authorized."
      );

      // require a valid candidate
      require(
        _candidateId > 0 && _candidateId <= candidatesCount,
        "Sender not authorized."
      );

      // record that voter has voted
      voters[msg.sender] = true;

      // update candidate vote Count
      candidates[_candidateId].voteCount ++;

      // trigger voted event
      emit votedEvent(_candidateId);
  }

}