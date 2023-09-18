// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error VotingSystem__InsufficientFunds();
error VotingSystem__NotTheOwner();
error VotingSystem__InvalidPollOption();
error VotingSystem__InvalidPoll();
error VotingSystem__AlreadyVoted();

contract VotingSystem {
    using PriceConverter for uint256;

    struct PollOption {
        string name;
        uint256 voteCount;
    }

    struct Poll {
        address creator;
        string creatorWorldcoinNullifierHash;
        string title;
        string description;
        uint256 creationTime;
        uint256 pollOptionCount;
        mapping(uint256 => PollOption) options;
        mapping(string => bool) hasVoted;
    }

    uint256 public s_pollCount;
    mapping(uint256 => Poll) public s_polls;

    address private immutable i_owner;
    AggregatorV3Interface public s_priceFeed;

    // A man gotta eat.
    uint256 private constant POLL_CREATION_PREMIUM_IN_USD = 1;

    event PollCreated(
        uint256 pollId,
        address indexed owner,
        string title,
        uint256 creationTime
    );
    event Voted(uint256 pollId, address indexed voter, uint256 optionIndex);

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }

    modifier hasEnoughFunds() {
        if (
            msg.value.getConversionRate(s_priceFeed) <
            POLL_CREATION_PREMIUM_IN_USD
        ) {
            revert VotingSystem__InsufficientFunds();
        }

        _;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert VotingSystem__NotTheOwner();
        }

        _;
    }

    function createPoll(
        string calldata title,
        string calldata description,
        string[] calldata optionNames,
        string calldata creatorWorldcoinNullifierHash
    ) external payable hasEnoughFunds {
        uint256 newPollId = s_pollCount;

        s_polls[newPollId].creator = msg.sender;
        s_polls[newPollId].creatorWorldcoinNullifierHash = creatorWorldcoinNullifierHash;
        s_polls[newPollId].title = title;
        s_polls[newPollId].description = description;
        s_polls[newPollId].creationTime = block.timestamp;
        s_polls[newPollId].pollOptionCount = optionNames.length;

        for (uint256 i = 0; i < optionNames.length; i++) {
            s_polls[newPollId].options[i] = PollOption(optionNames[i], 0);
        }

        s_pollCount++;

        emit PollCreated(newPollId, msg.sender, title, block.timestamp);
    }

    function vote(uint256 pollId, uint256 optionId, string calldata voterWorldcoinNullifierHash) external {
        if (pollId >= s_pollCount) {
            revert VotingSystem__InvalidPoll();
        }

        Poll storage poll = s_polls[pollId];

        if (poll.hasVoted[voterWorldcoinNullifierHash]) {
            revert VotingSystem__AlreadyVoted();
        }

        if (optionId >= poll.pollOptionCount) {
            revert VotingSystem__InvalidPollOption();
        }

        poll.hasVoted[voterWorldcoinNullifierHash] = true;
        poll.options[optionId].voteCount++;
    }

    function hasVoted(uint256 pollId, string calldata voterWorldcoinNullifierHash) external view returns (bool) {
        return s_polls[pollId].hasVoted[voterWorldcoinNullifierHash];
    }

    function getPollOption(
        uint256 pollId,
        uint256 optionId
    ) external view returns (string memory name, uint256 voteCount) {
        if (pollId >= s_pollCount) {
            revert VotingSystem__InvalidPoll();
        }

        Poll storage poll = s_polls[pollId];

        if (optionId >= poll.pollOptionCount) {
            revert VotingSystem__InvalidPollOption();
        }

        name = poll.options[optionId].name;
        voteCount = poll.options[optionId].voteCount;
    }

    function withdrawBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
