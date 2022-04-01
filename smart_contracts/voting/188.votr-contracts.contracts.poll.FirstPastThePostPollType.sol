// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '../poll/BasePollType.sol';

contract FirstPastThePostPollType is BasePollType {
  function getPollTypeName() external pure override returns (string memory) {
    return 'First Past The Post';
  }

  function vote(
    address voter,
    uint256[] memory _choices,
    int256[] memory amountOfVotes
  ) public override returns (bool) {
    require(hasVoted[msg.sender][voter] == false, 'You can only vote once');
    require(_choices.length == 1, 'You can only vote for one choice');
    return super.vote(voter, _choices, amountOfVotes);
  }
}
