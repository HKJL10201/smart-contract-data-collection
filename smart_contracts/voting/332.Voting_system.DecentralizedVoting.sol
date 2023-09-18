
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedVoting {
    address public owner;
    uint256 public votingStartTime;
    uint256 public votingEndTime;
    bool public votingOpen;
    
    struct Candidate {
        string name;
        uint256 voteCount;
    }
    
    Candidate[] public candidates;
    mapping(address => bool) public hasVoted;
    
    event VoteCasted(address indexed voter, uint256 candidateIndex);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    
    modifier onlyDuringVoting() {
        require(votingOpen, "Voting is not currently open");
        require(block.timestamp >= votingStartTime && block.timestamp <= votingEndTime, "Voting is not currently open");
        _;
    }
    
    constructor(uint256 _votingDurationInMinutes, string[] memory _candidateNames) {
        owner = msg.sender;
        votingStartTime = block.timestamp;
        votingEndTime = votingStartTime + _votingDurationInMinutes * 1 minutes;
        
        for (uint256 i = 0; i < _candidateNames.length; i++) {
            candidates.push(Candidate({
                name: _candidateNames[i],
                voteCount: 0
            }));
        }
    }
    
    function vote(uint256 _candidateIndex) external onlyDuringVoting {
        require(!hasVoted[msg.sender], "You have already voted");
        require(_candidateIndex < candidates.length, "Invalid candidate index");
        
        hasVoted[msg.sender] = true;
        candidates[_candidateIndex].voteCount++;
        
        emit VoteCasted(msg.sender, _candidateIndex);
    }
    
    function declareResults() external onlyOwner {
        require(block.timestamp > votingEndTime, "Voting is still ongoing");
        
        uint256 leadingCandidateIndex = 0;
        uint256 leadingVoteCount = 0;
        
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > leadingVoteCount) {
                leadingVoteCount = candidates[i].voteCount;
                leadingCandidateIndex = i;
            }
        }
        
        // Emit event or store the winner information
    }
}
