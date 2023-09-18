// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingContract {
    address public owner;
    mapping(address => bool) public hasVoted;
    mapping(string => uint256) public voteCount;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function vote(string memory candidate) external {
        // Ensure the sender hasn't voted before
        require(!hasVoted[msg.sender], "You have already voted");

        // Ensure the candidate is valid
        require(bytes(candidate).length > 0, "Candidate name cannot be empty");

        // Update the vote count for the candidate
        voteCount[candidate]++;

        // Mark the sender as having voted
        hasVoted[msg.sender] = true;
    }

    function getVoteCount(string memory candidate) external view returns (uint256) {
        return voteCount[candidate];
    }

    function closeVoting() external onlyOwner {
        // Ensure there is at least one candidate
        assert(getTotalCandidates() > 0);

        // Close the voting and transfer ownership to prevent further modifications
        owner = address(0);
    }

    function getTotalCandidates() public view returns (uint256) {
        return 1;  // In a real scenario, you would dynamically determine the total number of candidates
    }

    // Fallback function to reject incoming Ether
    receive() external payable {
        revert("Contract does not accept Ether");
    }
}

