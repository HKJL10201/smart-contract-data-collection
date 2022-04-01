// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '../poll/BasePollType.sol';

contract QuadraticPollType is BasePollType {
  function getPollTypeName() public pure override returns (string memory) {
    return 'Quadratic';
  }

  function vote(
    address voter,
    uint256[] memory _choices,
    int256[] memory amountOfVotes
  ) public override returns (bool) {
    require(hasVoted[msg.sender][voter] == false, 'You can only vote once');
    address votrPollAddress = msg.sender;
    int256 _amountOfAllVotesCasted = 0;
    for (uint256 i = 0; i < amountOfVotes.length; i++) {
      int256 _amountOfVotesCastForChoice = amountOfVotes[i];
      choiceIdToVoteCount[votrPollAddress][_choices[i]] += _amountOfVotesCastForChoice;
      if (!hasVoted[votrPollAddress][voter]) {
        amountOfVotersWhoAlreadyVoted[votrPollAddress]++;
      }
      hasVoted[votrPollAddress][voter] = true;
      _amountOfAllVotesCasted += abs(_amountOfVotesCastForChoice)**2;
    }
    int256 remainingAllowance = int256(IERC20(votrPollAddress).allowance(voter, address(this))) -
      _amountOfAllVotesCasted;
    require(remainingAllowance >= 0, 'Not enough allowance');
    IVotrPoll(votrPollAddress).burnFrom(voter, uint256(_amountOfAllVotesCasted));
    return true;
  }
}
