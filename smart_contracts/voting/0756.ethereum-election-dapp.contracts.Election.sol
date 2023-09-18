pragma solidity ^0.5.0;

contract Election {
  // Model a Candidate
  struct Candidate {
    uint id;
    string name;
    uint voteCount;
  }

  // Store & Fetch Candidate
  mapping(uint => Candidate) public candidates;

  // Store Candidates Count
  uint public candidatesCount;

  // Store accounts that have voted
  mapping(address => bool) public voters;

  // Voted event
  event votedEvent (uint indexed _candidateId);

  // Constructor
  constructor () public {
    addCandidate("Candidate 1");
    addCandidate("Candidate 2");
    addCandidate("Candidate 3");
    addCandidate("Candidate 4");
    addCandidate("Candidate 5");
  }

  // Add Candidate
  function addCandidate (string memory _name) private {
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }

  // Vote for Candidate
  function vote (uint _candidateId) public {
    // require that they have not voted before
    require(!voters[msg.sender]);

    // require a valid candidate
    require(_candidateId > 0 && _candidateId <= candidatesCount);

    // record that voter has voted
    voters[msg.sender] = true;

    // update candidate vote count
    candidates[_candidateId].voteCount++;

    // trigger voted event
    emit votedEvent(_candidateId);
  }
}
