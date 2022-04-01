// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '../interfaces/IPollType.sol';
import '../interfaces/IVotrPoll.sol';
import '../poll/VotrPoll.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

abstract contract BasePollType is IPollType {
  mapping(address => mapping(uint256 => int256)) public choiceIdToVoteCount;
  mapping(address => mapping(address => bool)) public hasVoted;
  mapping(address => uint256) public amountOfVotersWhoAlreadyVoted;

  function onInit(address poll, address owner) public pure override {} // solhint-disable-line

  function vote(
    address voter,
    uint256[] memory _choices,
    int256[] memory amountOfVotes
  ) public virtual override returns (bool) {
    address votrPollAddress = msg.sender;
    int256 _amountOfAllVotesCasted = 0;
    for (uint256 i = 0; i < amountOfVotes.length; i++) {
      int256 _amountOfVotesCastForChoice = amountOfVotes[i];
      choiceIdToVoteCount[votrPollAddress][_choices[i]] += _amountOfVotesCastForChoice;
      if (!hasVoted[votrPollAddress][voter]) {
        amountOfVotersWhoAlreadyVoted[votrPollAddress]++;
      }
      hasVoted[votrPollAddress][voter] = true;
      _amountOfAllVotesCasted += abs(_amountOfVotesCastForChoice);
    }
    int256 remainingAllowance = int256(IERC20(votrPollAddress).allowance(voter, address(this))) -
      _amountOfAllVotesCasted;
    require(remainingAllowance >= 0, 'Not enough allowance');
    IVotrPoll(votrPollAddress).burnFrom(voter, uint256(_amountOfAllVotesCasted));
    return true;
  }

  function abs(int256 x) internal pure returns (int256) {
    return x > 0 ? x : -x;
  }

  function checkWinner(uint256 _amountOfChoices) public view override returns (uint256 winnerIndex) {
    int256 winningAmountOfVotes = 0;
    for (uint256 i = 0; i < _amountOfChoices; i++) {
      if (choiceIdToVoteCount[msg.sender][i] > winningAmountOfVotes) {
        winningAmountOfVotes = choiceIdToVoteCount[msg.sender][i];
        winnerIndex = i;
      }
    }
    return winnerIndex;
  }

  function getAmountOfVotesForChoice(uint256 choiceId) public view override returns (int256 voteCount) {
    return choiceIdToVoteCount[msg.sender][choiceId];
  }

  function isFinished(uint256 _quorum, uint256 _endDate)
    public
    view
    override
    returns (bool finished, bool quorumReached)
  {
    if (_endDate < block.timestamp) {
      finished = true;
    }
    if (amountOfVotersWhoAlreadyVoted[msg.sender] >= _quorum) {
      quorumReached = true;
    }
  }

  function delegateVote(
    address from,
    address to,
    uint256 amount
  ) public override returns (bool) {
    IERC20(msg.sender).transferFrom(from, to, amount);
    return true;
  }
}
