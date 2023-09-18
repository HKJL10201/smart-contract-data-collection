// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPollType {
  event Voted(address indexed who, uint256 indexed chosen, int256 votesAmount);

  function getPollTypeName() external pure returns (string memory);

  function onInit(address poll, address owner) external;

  function vote(
    address voter,
    uint256[] memory choices,
    int256[] memory amountOfVotes
  ) external returns (bool);

  function checkWinner(uint256 _amountOfChoices) external view returns (uint256 winnerIndex);

  function getAmountOfVotesForChoice(uint256 choiceId) external view returns (int256 voteCount);

  function isFinished(uint256 _quorum, uint256 _endDate) external view returns (bool finished, bool quorumReached);

  function delegateVote(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}
