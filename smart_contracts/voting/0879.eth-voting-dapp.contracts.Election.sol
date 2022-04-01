pragma solidity ^0.5.0;

contract Election {
    // Model a Candidate
    struct Candidate {
      uint id;
      string name;
      uint voteCount;
    }

    // Read/write Candidates
    mapping(uint => Candidate) public candidates;
    // Store account that have voted
    mapping(address => bool) public voters;

    // Store Candidates Count
    uint public candidatesCount;

    event votedEvent(
      uint indexed _candidateId
    );

    // Constructor
    constructor () public {
      addCandidate("Candidate 1");
      addCandidate("Candidate 2");
    }

    function addCandidate(string memory _name) private {
      candidatesCount++;
      candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint _candidateId) public {
      // require that they haven't voted before
      require(!voters[msg.sender], "This account has already voted.");

      // require a valid candidate
      require(_candidateId > 0 && _candidateId <= candidatesCount, "This candidate is invalid");

      // record that voter has voted
      voters[msg.sender] = true;

      // update candidate vote Count
      candidates[_candidateId].voteCount++;

      // trigger voted event
      emit votedEvent(_candidateId);
    }

}