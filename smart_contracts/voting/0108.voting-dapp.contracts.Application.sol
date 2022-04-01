// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Poll.sol";

contract Application {
    // Owner
    address public owner;

    // To store all polls
    mapping(uint256 => address) public polls;

    // Total number of polls
    uint256 public nPolls;

    // On successful poll creation
    event PollCreated(address pollAddress, address ownerAddress);

    constructor() {
        owner = msg.sender;
    }

    // A function to deploy new poll contract
    function createPoll(
        string memory _title,
        string memory _description,
        string[] memory _options
    ) public {
        bytes32 emptyHash = keccak256(bytes(""));

        // To check _title is not empty string
        require(keccak256(bytes(_title)) != emptyHash, "Title can't be empty");
        // To check _description is not empty string
        require(
            keccak256(bytes(_description)) != emptyHash,
            "Description can't be empty"
        );
        // To check _options is not empty string
        for (uint256 i = 0; i < _options.length; i++) {
            require(
                keccak256(bytes(_options[i])) != emptyHash,
                "Options can't be empty"
            );
        }

        // Create and deploy contract
        Poll _poll = new Poll(msg.sender, _title, _description, _options);

        // Store poll contract address for fetching afterwards
        polls[nPolls] = address(_poll);
        nPolls++;

        // Let the frontend know after success
        emit PollCreated(address(_poll), msg.sender);
    }

    // Get poll overview by index
    function getPollOverview(uint256 _index, address _user)
        public
        view
        returns (
            address pollAddress,
            string memory title,
            string memory description,
            address _owner,
            uint256 nOptions,
            bool isResultAnnounced,
            uint256 totalVotes,
            bool hasUserVoted
        )
    {
        Poll _poll = Poll(polls[_index]);

        bool _hasUserVoted = _poll.voters(_user);

        // Returns contract address and other details of poll
        return (
            polls[_index],
            _poll.title(),
            _poll.description(),
            _poll.owner(),
            _poll.nOptions(),
            _poll.isResultAnnounced(),
            _poll.totalVotes(),
            _hasUserVoted
        );
    }
}
