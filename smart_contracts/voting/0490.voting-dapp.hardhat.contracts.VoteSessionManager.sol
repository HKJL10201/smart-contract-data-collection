//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./VoteSession.sol";

/// @title A voting sessions manager
/// @author Rares Stanciu
/// @notice You can use this contract to manage multiple voting sessions.
contract VoteSessionManager {
  VoteSession[] public voteSessions;

  /// @notice Function called for creating a new voting session
  function createVoteSession(
    string memory _title,
    uint256 _startDate,
    uint256 _duration
  ) external returns (address) {
    // Create new VoteSession
    VoteSession voteSession = new VoteSession(_title, _startDate, _duration);
    voteSessions.push(voteSession);

    return address(voteSession);
  }
}
