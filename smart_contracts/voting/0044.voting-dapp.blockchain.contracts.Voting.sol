// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Voting {
    // Track Voter Registration
    mapping(address => bool) public voters;
    // Track Voters Voted
    mapping(address => bool) public hasVoted;
    // Track Candidates
    mapping(address => Candidate) public candidates;

    struct Candidate {
        address candidateAddress;
        string name;
        uint voteCount;
    }
    // Track Votes Tally
    uint public totalVotes;
    // Contract Owner
    address public owner;
    address public ec;

    constructor() {
        owner = msg.sender;
    }

    //modifier to check if is ec
    modifier isEC() {
        require(ec == msg.sender, "Not Electoral commissioner!");
        _;
    }

    //modifier to check if is owner
    modifier isOwner() {
        require(owner == msg.sender, "Not owner!");
        _;
    }

    //register EC
    function registerEC(address ecAddress) public isOwner {
        // Check If Sender is Owner
        // Register
        ec = ecAddress;
    }

    // Register Voter
    function registerVoter(address voterAddress) public isEC {
        // Register
        voters[voterAddress] = true;
    }

    // Add Candidate
    function addCandidate(
        address candidateAddress,
        string memory name
    ) public isEC {
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
