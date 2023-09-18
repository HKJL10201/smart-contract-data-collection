//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

contract FoodVoter {
    uint public candidateKey;
    event Voted(uint candidateId);
    
    // Voter struct
    struct Voter {
        uint votes;
        bool voted;
        string chosenCandidate;
    }
    
    // Candidate struct
    struct Candidate {
        uint votes;
        string name;
    }
    
    
    // Lookup each address to the Voter struct
    mapping(address => Voter) public voters;
    address[] public voterAccts;
    
    // Lookup candidates
    mapping(uint => Candidate) public candidates;
    uint[] public candidateAccts;
    
    // Create voters
    function createVoter() public returns (string memory) {
        Voter storage voter = voters[msg.sender];
        
        voter.votes = 1;
        voter.voted = false;
        voter.chosenCandidate = "Hasn't voted yet";
        
        voterAccts.push(msg.sender);
        return "Account successfully created...";
    }
    
    //Retrieve voter votes
    function getVoterVotes() public view returns (uint) {
        Voter storage voter = voters[msg.sender];
        
        return voter.votes;
    }
    
    // Check if voter has voted
    function hasVoted() public view returns (bool) {
        Voter storage voter = voters[msg.sender];
        
        return voter.voted;
    }
    
    // Create candidates
    function creatCandidate(string memory _name) public returns (uint) {
        candidateKey += 1;
        Candidate storage candidate = candidates[candidateKey];
        
        candidate.name = _name;
        candidate.votes = 0;
        
        candidateAccts.push(candidateKey);
        return candidateKey;
    }
    
    // Retrieve candidate votes
    function getCandidateVotes(uint _key) public view returns (uint) {
        Candidate storage candidate = candidates[_key];
        
        return candidate.votes;
    }
    
    // Get list of candidates
    function getamountOfCandidates() public view returns(uint) {
        return candidateAccts.length;
    }
    
    
    // Delegate extra votes (onlyOwner)
    function delegate(address _address) public {
        Voter storage voter = voters[_address];
        
        voter.votes += 1;
    }
    
    // Vote for candidates
    function vote(uint _key) public {
        require(voters[msg.sender].votes >= 1);
        Candidate storage candidate = candidates[_key];
        Voter storage voter = voters[msg.sender];

        voter.voted = true;
        candidate.votes += 1;
        voter.votes -= 1;
        emit Voted(_key);
   }
    
    
    
}