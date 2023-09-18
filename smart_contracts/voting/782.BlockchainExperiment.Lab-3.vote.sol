// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VotingContract
 * @dev A smart contract for conducting voting with multiple options and time constraints.
 * @author Kai Lei, Yanming Shao
 */
contract VotingContract {
    address public owner;           // Contract owner's address
    uint256 public votingStartTime; // Opening time of the voting
    uint256 public votingEndTime;   // Closing time of the voting
    bool public votingActive;       // Voting status (active or inactive)

    // Information about the voter (registered or not, voted or not, index of options voted)
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedOption;
    }

    // Name and number of votes for each ballot option
    struct Option {
        string name;
        uint256 voteCount;
    }

    mapping(address => Voter) public voters;
    Option[] public options;

    // Ensure that only the contract owner can call specific functions
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    // Ensure that only registered voters can call specific functions
    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].isRegistered, "You are not a registered voter");
        _;
    }

    // Ensure that specific functions can only be called during voting
    modifier onlyDuringVotingPeriod() {
        require(votingActive, "Voting is not active");
        require(block.timestamp >= votingStartTime && block.timestamp <= votingEndTime, "Voting is outside the allowed period");
        _;
    }

    // Ensure that specific functions can only be called before voting begins
    modifier onlyBeforeVotingPeriod() {
        require(!votingActive, "Voting is already active");
        _;
    }

    /**
     * @dev Constructor function to initialize the VotingContract with options and duration.
     * @param _votingDurationHours The duration of the voting period in hours.
     * @param _optionNames An array of strings representing the names of the voting options.
     */
    constructor(uint256 _votingDurationHours, string[] memory _optionNames) {
        require(_votingDurationHours > 0, "Voting duration must be positive");
        require(_optionNames.length > 1, "Please provide at least two voting options");

        owner = msg.sender;
        votingStartTime = 0;
        votingEndTime = 0;
        votingActive = false;

        for (uint256 i = 0; i < _optionNames.length; i++) {
            options.push(Option({ name: _optionNames[i], voteCount: 0 }));
        }
    }

    /**
     * @dev Start the voting period. Only the contract owner can call this function.
     *      Once voting starts, the voting period will last for a predefined duration.
     */
    function startVoting() external onlyOwner onlyBeforeVotingPeriod {
        // TODO: Your code here
    }

    /**
     * @dev Register a voter. Only the contract owner can call this function.
     * @param _voter The address of the voter to register.
     */
    function registerVoter(address _voter) external onlyOwner onlyBeforeVotingPeriod {
        require(!voters[_voter].isRegistered, "Voter is already registered");
        // TODO: Your code here
    }

    /**
     * @dev Cast a vote for a specific voting option.
     * @param _optionIndex The index of the option to vote for.
     */
    function vote(uint256 _optionIndex) external onlyRegisteredVoter onlyDuringVotingPeriod {
        require(_optionIndex < options.length, "Invalid option index");
        require(!voters[msg.sender].hasVoted, "You have already voted");
        // TODO: Your code here
    }

    /**
     * @dev End the voting period. Only the contract owner can call this function.
     *      Once voting ends, no more votes can be cast.
     */
    function endVoting() external onlyOwner onlyDuringVotingPeriod {
        // TODO: Your code here
    }

    /**
     * @dev Get the total number of voting options.
     * @return The total number of voting options.
     */
    function getOptionsCount() external view returns (uint256) {
        return options.length;
    }

    /**
     * @dev Get the name and vote count of a specific voting option.
     * @param _optionIndex The index of the option to retrieve information about.
     * @return The name and vote count of the specified option.
     */
    function getOption(uint256 _optionIndex) external view returns (string memory, uint256) {
        require(_optionIndex < options.length, "Invalid option index");
        return (options[_optionIndex].name, options[_optionIndex].voteCount);
    }

    /**
     * @dev Check if the voting period has ended.
     * @return True if the voting period has ended, false otherwise.
     */
    function hasVotingEnded() external view returns (bool) {
        return !votingActive && block.timestamp > votingEndTime;
    }

    /**
     * @dev Check if a voter is registered.
     * @param _voter The address of the voter to check.
     * @return True if the voter is registered, false otherwise.
     */
    function isVoterRegistered(address _voter) external view returns (bool) {
        return voters[_voter].isRegistered;
    }

    /**
     * @dev Check if a voter has already voted.
     * @param _voter The address of the voter to check.
     * @return True if the voter has already voted, false otherwise.
     */
    function hasVoterVoted(address _voter) external view returns (bool) {
        return voters[_voter].hasVoted;
    }

    /**
     * @dev Get the index of the voting option a voter has voted for.
     * @param _voter The address of the voter to check.
     * @return The index of the voting option the voter has voted for.
     */
    function getVoterVote(address _voter) external view returns (uint256) {
        return voters[_voter].votedOption;
    }
}
