// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Poll {
    // Address that creates voting program
    address public owner;

    // Program Title
    string public title;

    // Program Description
    string public description;

    // To check if results have been announced
    bool public isResultAnnounced;

    // To store all the addresses who have already voted
    mapping(address => bool) public voters;

    // Option struct
    struct Option {
        string name;
        uint256 count;
    }

    // Number of options
    uint256 public nOptions = 0;

    // Mapping for counting votes to each option
    mapping(uint256 => Option) private optionCounts;

    // Mapping for keeping vote count after results announced
    mapping(uint256 => Option) public results;

    // Index of option with max votes
    uint256 private maxVotesIndex = 0;

    // Current max votes to any option
    uint256 private maxVotes = 0;

    // Total votes
    uint256 public totalVotes = 0;

    // Emitted when results are announced successfully
    event ResultAnnounced(Option winnerOption);

    constructor(
        address _owner,
        string memory _title,
        string memory _description,
        string[] memory _options
    ) {
        owner = _owner;
        title = _title;
        description = _description;
        nOptions = _options.length;

        // Create mapping of index => Option(name, count)
        for (uint256 i = 0; i < nOptions; i++) {
            optionCounts[i] = Option(_options[i], 0);
        }
    }

    // Function to cast vote
    function vote(uint256 index) public {
        // Check if result already announced
        require(!isResultAnnounced, "Cannot vote after result announcement");
        // Check if voter has already voted
        require(!voters[msg.sender], "You have already voted");
        // Vote for option corresponding to index
        optionCounts[index].count++;
        // Adjust option with maximum votes
        if (optionCounts[index].count > maxVotes) {
            maxVotes = optionCounts[index].count;
            maxVotesIndex = index;
        }
        // Mark as voted
        voters[msg.sender] = true;
        // Increase total votes
        totalVotes++;
    }

    // Function to announce results which can be called by only owner
    function announceResult() public {
        // Check if results already announced
        require(!isResultAnnounced, "Result already announced");
        // Check if caller is owner
        require(msg.sender == owner, "Only owner can announce result");

        // Mark result as announced
        isResultAnnounced = true;

        // Create public mapping
        for (uint256 i = 0; i < nOptions; i++) {
            results[i] = optionCounts[i];
        }

        // Emit event along with result data
        emit ResultAnnounced(optionCounts[maxVotesIndex]);
    }

    // Function to return options
    function getOption(uint256 _index) public view returns (string memory) {
        return optionCounts[_index].name;
    }

    // Function to get Winner after results announced
    function getWinner() public view returns (Option memory) {
        // Check if results already announced
        require(isResultAnnounced, "Result not announced yet");
        require(totalVotes > 0, "No one has voted yet");

        return optionCounts[maxVotesIndex];
    }
}
