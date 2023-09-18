pragma solidity ^0.4.24;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Store accounts that have voted
    // address is the account number.
    mapping(address => bool) public voters;

    // Store accounts that have voted
    // address is the account number.
    mapping(address => string) public candidateSelected;

    // Store Candidates
    // Fetch Candidates
    mapping(uint => Candidate) public candidates;

    // Store Candidates Count
    uint public candidatesCount;

    // Constructor
    constructor() public {
        createCandidate("YES");
        createCandidate("NO");
    }

    /**
      * Create a new Candidate.
      */
    function createCandidate(string _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    /**
      * This method vote for one candidate.
      */
    function vote (uint _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender], "You already voted.");

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount, "This candidate doesn't exist.");
        
        // record that voter has voted
        // msg.sender is the user account number.
        voters[msg.sender] = true;
        candidateSelected[msg.sender] = candidates[_candidateId].name;

        // update candidate vote Count
        candidates[_candidateId].voteCount++;
    }
}
