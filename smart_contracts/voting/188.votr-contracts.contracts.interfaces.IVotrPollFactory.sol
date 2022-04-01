// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVotrPollFactory {
  event Voted(address indexed pollAddress, address indexed who, uint256[] choices, int256[] votesAmount);
  event PollCreated(address indexed owner, address indexed pollAddress);

  struct TokenSettings {
    address basedOnToken;
    string name;
    string symbol;
  }
  struct PollSettings {
    string title;
    string description;
    address chairman;
    uint256 quorum;
    uint256 endDate;
    bool allowVoteDelegation;
    address callbackContractAddress;
  }
  struct Voter {
    address addr;
    uint256 allowedVotes;
  }

  function createPoll(
    address _pollType,
    TokenSettings memory _tokenSettings,
    PollSettings memory _pollSettings,
    string[] memory _choices,
    Voter[] memory _voters
  ) external returns (address);

  function emitVotedEvent(
    address who,
    uint256[] memory choices,
    int256[] memory votesAmount
  ) external;
}
