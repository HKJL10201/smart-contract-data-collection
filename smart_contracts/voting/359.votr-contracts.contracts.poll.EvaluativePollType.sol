// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '../poll/BasePollType.sol';

contract EvaluativePollType is BasePollType {
  function getPollTypeName() external pure override returns (string memory) {
    return 'Evaluative';
  }

  function vote(
    address voter,
    uint256[] memory _choices,
    int256[] memory amountOfVotes
  ) public override returns (bool) {
    for (uint256 i = 0; i < amountOfVotes.length; i++) {
      int256 amount = amountOfVotes[i];
      require(amount == 1 || amount == -1, 'You can only vote for or against this choice (1,-1)');
      require(hasVoted[msg.sender][voter] == false, 'You can only vote once');
    }
    return super.vote(voter, _choices, amountOfVotes);
  }
}
