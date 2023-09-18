pragma solidity ^0.4.24;

contract Election {
  // Model a Candidate
  struct Candidate {
    uint id;
    string name;
    uint voteCount;
  }

  // Store account that have voted
  mapping(address => bool) public voters;

  // Store Candidate
  // Fetch Candidate
  mapping(uint => Candidate) public candidates;

  // Store Candidate Count. Default is 0
  uint public candidatesCount;

  constructor() public {
    addCandidate("Luffy");
    addCandidate("Zoro");
  }

  // DApps can listen the event
  event VotedEvent (
    uint indexed _candidateId
  );

  function vote (uint _candidateId) public {
    // Require that they haven't voted before
    // require() to validate user's input before any action can be taken
    // Stop execution and throw exception if false
    require(!voters[msg.sender]);

    // Require a valid candidate
    require(_candidateId > 0 && _candidateId <= candidatesCount);

    // Record that voter has voted
    // msg.sender is the address currently interacting with the contract or is the one who is sending transaction
    voters[msg.sender] = true;

    // Increate candidate voteCount
    candidates[_candidateId].voteCount++;

    // Trigger VotedEvent
    emit VotedEvent(_candidateId);
  }

  function addCandidate (string _name) private {
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }
}