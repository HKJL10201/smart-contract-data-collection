// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Voting {
    // Track Voter Registration
    mapping(address => bool) voters;
    // Track Voters Voted
    mapping(address => bool) hasVoted;
    // Track Candidates
    mapping(address => Candidate) candidates;

    struct Candidate {
        address candidateAddress;
        string name;
        uint voteCount;
    }
    // Track Votes Tally
    uint totalVotes;
    // Contract Owner
    address owner;

    constructor() {
        owner = msg.sender;
    }

    // Register Voter
    function registerVoter(address voterAddress) public {
        // Check If Sender is Owner
        require(owner == msg.sender, "Not Owner!");
        // Register
        voters[voterAddress] = true;
    }

    // Add Candidate
    function addCandidate(address candidateAddress, string memory name) public {
        // Check If Sender is Owner
        require(owner == msg.sender, "Not Owner!");
        // Add Candidate
        candidates[candidateAddress] = Candidate(candidateAddress, name, 0);
    }

    // Vote
    function vote(address candidateAddress) public {
        // Check if voter is registered
        require(voters[msg.sender], "Voter is not registered!");
        // Check if voter has not voted
        require(!hasVoted[msg.sender], "Voter has already voted!");
        // Check if candidate is valid
        require(
            candidates[candidateAddress].candidateAddress == candidateAddress,
            "Candidate not valid!"
        );
        // Increase candidate vote
        candidates[candidateAddress].voteCount++;
        // Mark voter as voted
        voters[msg.sender] = true;
        // Increase the vote tally
        totalVotes++;
    }
}
