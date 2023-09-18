pragma solidity >=0.4.21 <0.7.0;

contract Election {
  // Model a candidate
  struct Candidate {
    uint id;
    string name;
    uint voteCount;
  }

  // Store accounts that have voted
  mapping(address => bool) public voters;

  // Store candidates
  // Fetch candidates
  mapping(uint => Candidate) public candidates;
  // Store candidates count
  uint public candidatesCount;

  event votedEvent (
    uint indexed _candidateId
  );

  // Run everytime we init our contract with migrations
  constructor() public {
    addCandidate('Candidate 1');
    addCandidate('Candidate 2');
  }

  function addCandidate (string memory _name) private {
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }

  function vote (uint _candidateId) public {
    // Confirm voter has never voted before
    require(!voters[msg.sender], 'First time voter required.');

    // Require candidateId to be valid
    require(_candidateId > 0 && _candidateId <= candidatesCount, 'Candidate ID must be valid.');

    // Record that voter has voted
    voters[msg.sender] = true;

    // Update candidate's vote
    candidates[_candidateId].voteCount ++;

    // Trigger voted event
    emit votedEvent(_candidateId);
  }
}