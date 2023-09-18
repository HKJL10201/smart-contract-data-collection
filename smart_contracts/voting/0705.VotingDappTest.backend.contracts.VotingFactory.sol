//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./VotingPoll.sol";

contract VotingFactory {
    struct Poll {
        uint256 id;
        address addr;
        address owner;
        string title;
        string[] options;
    }

    // Mapping for Poll id to Poll
//    mapping(uint256 => Poll) public polls;
    Poll[] private polls;
    uint256 public pollCount;

    event PollCreated(
        uint256 pollId,
        address owner,
        string title,
        string[] options
    );

    constructor() {}

    function createPoll(string memory _title, string[] memory options)
        external
    {
        require(options.length >= 2, "Wrong Options");

        VotingPoll votingPoll = new VotingPoll(_title, msg.sender);

        Poll memory newPoll = Poll(
            pollCount,
            address(votingPoll),
            msg.sender,
            _title,
            options
        );

        polls.push(newPoll);

        emit PollCreated(pollCount, msg.sender, _title, options);

        pollCount++;
    }

    function getPolls() external view returns (Poll[] memory) {
        return polls;
    }
}
