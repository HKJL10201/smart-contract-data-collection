// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";

contract VotingSystem {
    // Define a struct to store the information for each vote
    struct Vote {
        string question; // The question of the vote
        uint256[] options; // The options for the vote
        bool closed; // Whether the vote is closed or not
        uint256[] votes; // The number of votes for each option
    }

    // Mapping to store all the votes, with the vote id as the key
    mapping(uint256 => Vote) public votes;
    // Keep track of the number of votes that have been created
    uint256 public voteCounter;

    // Event to be emitted when a new vote is created
    event VoteCreated(uint256 voteId);
    // Event to be emitted when a vote is cast
    event VoteCast(uint256 voteId, uint256 option);
    // Event to be emitted when a vote is closed
    event VoteClosed(uint256 voteId);

    // Function to create a new vote
    function createVote(
        string memory _question,
        uint256[] memory _options
    ) public {
        // Store the vote information in the votes mapping
        votes[voteCounter] = Vote(
            _question,
            _options,
            false,
            new uint256[](_options.length)
        );
        // Emit the VoteCreated event with the vote id
        emit VoteCreated(voteCounter);
        // Increment the voteCounter to keep track of the number of votes
        voteCounter++;
    }

    // Function to cast a vote for a given option
    function castVote(uint256 _voteId, uint256 _option) public {
        // Retrieve the vote information from the votes mapping
        Vote storage vote = votes[_voteId];
        // Check if the vote is closed
        require(!vote.closed, "Vote is closed");
        // Check if the option being voted for exists
        require(_option < vote.options.length, "Option does not exist");
        // Increment the number of votes for the selected option
        vote.votes[_option]++;
        // Emit the VoteCast event with the vote id and the option
        emit VoteCast(_voteId, _option);
    }

    // Function to close a vote
    function closeVote(uint256 _voteId) public {
        // Retrieve the vote information from the votes mapping
        Vote storage vote = votes[_voteId];
        // Check if the vote is already closed
        require(!vote.closed, "Vote is already closed");
        // Set the closed status of the vote to true
        vote.closed = true;
        // Emit the VoteClosed event with the vote id
        emit VoteClosed(_voteId);
    }

    // Function to retrieve the information for a vote
    function getVote(
        uint256 _voteId
    ) public view returns (string memory, uint256[] memory, bool) {
        // Retrieve the vote information from the votes mapping
        Vote storage vote = votes[_voteId];
        // Return the question, options, and closed status of the vote
        return (vote.question, vote.options, vote.closed);
    }
}
