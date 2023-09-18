// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IVotrPollFactory.sol';
import '../poll/VotrPoll.sol';

contract VotrPollFactory is IVotrPollFactory {
  uint256 public numberOfPolls;
  address[] public allPolls;
  mapping(address => bool) public doesPollExist;

  function createPoll(
    address _pollType,
    TokenSettings memory _tokenSettings,
    PollSettings memory _pollSettings,
    string[] memory _choices,
    Voter[] memory _voters
  ) external override returns (address) {
    VotrPoll poll = new VotrPoll(
      msg.sender,
      address(this),
      _pollType,
      _tokenSettings,
      _pollSettings,
      _choices,
      _voters
    );
    return _createPoll(msg.sender, address(poll));
  }

  modifier callableOnlyByVotrPoll() {
    require(doesPollExist[msg.sender] == true, 'Callable only by Votr polls');
    _;
  }

  function emitVotedEvent(
    address who,
    uint256[] memory choices,
    int256[] memory votesAmount
  ) external override callableOnlyByVotrPoll {
    emit Voted(msg.sender, who, choices, votesAmount);
  }

  function _createPoll(address owner, address poll) internal returns (address) {
    emit PollCreated(owner, poll);
    numberOfPolls++;
    allPolls.push(poll);
    doesPollExist[poll] = true;
    return poll;
  }
}
