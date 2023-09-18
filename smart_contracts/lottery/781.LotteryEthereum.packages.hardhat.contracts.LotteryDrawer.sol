pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

// import 'hardhat/console.sol';
import './LotteryFactory.sol';

// import './LotteryHelper.sol';

contract LotteryDrawer is LotteryFactory {
  using SafeMath for uint256;

  uint256 constant zeroAsU256 = 0;
  uint32 constant zeroAsU32 = 0;

  // Saving them as constant to save in bytecode contract, saving some gas ?
  uint256 constant twoWinningNumbersSplit = 1000; // 10%
  uint256 constant threeWinningNumbersSplit = 1500; // 15%
  uint256 constant fourWinningNumbersSplit = 2500; // 25%
  uint256 constant fiveWinningNumbersSplit = 4500; // 45%
  uint256 constant devFeePercent = 150; // 0.75%
  uint256 constant burnPercent = 150; // 1.5%
  uint256 constant stakingPercent = 200; // 2%

  struct Draw {
    uint256 id;
    uint8[5] numbers;
    bool completed;
    uint256 rewardBalanceAtDraw;
    uint256[6] rewardsByWinningNumber; // [0, 0, 0.2, 0.4, 0.8, 1.5] : 4 winning numbers ticket can claim 0.8, 5 winning numbers ticket can claim 1.5, ...
    uint32[6] winnersByWinningNumber; // [90, 47, 41, 7, 1, 0] : 1 ticket has 4 winning numbers, 0 ticket has 5 winning numbers
    uint256 startedAt;
  }

  Draw[] public draws;

  constructor(address _LTY) LotteryFactory(_LTY) {
    uint256[6] memory rewardsByWinningNumber = [zeroAsU256, zeroAsU256, zeroAsU256, zeroAsU256, zeroAsU256, zeroAsU256];
    uint32[6] memory winnersByWinningNumber = [zeroAsU32, zeroAsU32, zeroAsU32, zeroAsU32, zeroAsU32, zeroAsU32];

    draws.push(Draw(0, [0, 0, 0, 0, 0], false, 0, rewardsByWinningNumber, winnersByWinningNumber, block.timestamp));
  }

  function nextDraw() internal {
    lotteryCount = lotteryCount.add(1);
    uint256[6] memory rewardsByWinningNumber = [zeroAsU256, zeroAsU256, zeroAsU256, zeroAsU256, zeroAsU256, zeroAsU256];
    uint32[6] memory winnersByWinningNumber = [zeroAsU32, zeroAsU32, zeroAsU32, zeroAsU32, zeroAsU32, zeroAsU32];

    draws.push(Draw(lotteryCount, [0, 0, 0, 0, 0], false, 0, rewardsByWinningNumber, winnersByWinningNumber, block.timestamp));
  }

  function processDraw() internal returns (bool) {
    uint256 drawCount = draws.length.sub(1);
    uint256 randomSeed = uint256(randomGenerator.getRandomNumber(drawCount));
    uint8[5] memory drawNumbers = generateRandomTicketNumbers(randomSeed);
    uint32[6] memory winnersByWinningNumber = [uint32(0), uint32(0), uint32(0), uint32(0), uint32(0), uint32(0)];
    uint256[6] memory rewardsByWinningNumber = [zeroAsU256, zeroAsU256, zeroAsU256, zeroAsU256, zeroAsU256, zeroAsU256];

    uint256 balance = _getBalance();
    uint256[] memory ticketInDraw = drawToTickets[drawCount];
    uint256 ticketInDrawCount = ticketInDraw.length;

    for (uint256 i = 0; i < ticketInDrawCount; i++) {
      uint8[5] memory ticketNumbers = tickets[ticketInDraw[i]].numbers;
      uint256 commonNumbers = compareTwoUintArray(drawNumbers, ticketNumbers);

      if (commonNumbers == 0) {
        winnersByWinningNumber[0] = winnersByWinningNumber[0] + 1;
      } else if (commonNumbers == 1) {
        winnersByWinningNumber[1] = winnersByWinningNumber[1] + 1;
      } else if (commonNumbers == 2) {
        winnersByWinningNumber[2] = winnersByWinningNumber[2] + 1;
      } else if (commonNumbers == 3) {
        winnersByWinningNumber[3] = winnersByWinningNumber[3] + 1;
      } else if (commonNumbers == 4) {
        winnersByWinningNumber[4] = winnersByWinningNumber[4] + 1;
      } else if (commonNumbers == 5) {
        winnersByWinningNumber[5] = winnersByWinningNumber[5] + 1;
      } else {
        revert("Couldn't define status for ticket");
      }
    }

    // Calculate balance to add to every winner

    rewardsByWinningNumber[2] = winnersByWinningNumber[2] > 0 ? ((balance.div(10000)).mul(twoWinningNumbersSplit)).div(winnersByWinningNumber[2]) : 0;
    rewardsByWinningNumber[3] = winnersByWinningNumber[3] > 0 ? ((balance.div(10000)).mul(threeWinningNumbersSplit)).div(winnersByWinningNumber[3]) : 0;
    rewardsByWinningNumber[4] = winnersByWinningNumber[4] > 0 ? ((balance.div(10000)).mul(fourWinningNumbersSplit)).div(winnersByWinningNumber[4]) : 0;
    rewardsByWinningNumber[5] = winnersByWinningNumber[5] > 0 ? ((balance.div(10000)).mul(fiveWinningNumbersSplit)).div(winnersByWinningNumber[5]) : 0;
    uint256 devFeeBalanceToAdd = ((balance.div(10000)).mul(devFeePercent));
    uint256 stakingBalanceToAdd = ((balance.div(10000)).mul(stakingPercent));
    uint256 burnBalanceToAdd = ((balance.div(10000)).mul(burnPercent));

    // console.log(rewardsByWinningNumber[2], rewardsByWinningNumber[3], rewardsByWinningNumber[4]);

    // Store values
    devFeeBalance = devFeeBalance.add(devFeeBalanceToAdd);
    stakingBalance = stakingBalance.add(stakingBalanceToAdd);
    burnBalance = burnBalance.add(burnBalanceToAdd);
    claimableBalance = claimableBalance.add(
      rewardsByWinningNumber[2]
        .mul(winnersByWinningNumber[2])
        .add(rewardsByWinningNumber[3].mul(winnersByWinningNumber[3]))
        .add(rewardsByWinningNumber[4].mul(winnersByWinningNumber[4]))
        .add(rewardsByWinningNumber[5].mul(winnersByWinningNumber[5]))
    );

    draws[drawCount].completed = true;
    draws[drawCount].numbers = drawNumbers;
    draws[drawCount].rewardBalanceAtDraw = balance;
    draws[drawCount].rewardsByWinningNumber = rewardsByWinningNumber;
    draws[drawCount].winnersByWinningNumber = winnersByWinningNumber;
    draws[drawCount].numbers = drawNumbers;

    // draws[draws.length] = currentDraw; // Storage
    nextDraw();
    return true;
  }

  // GETTERS

  function _getAllDraws() external view returns (Draw[] memory) {
    Draw[] memory _draws = new Draw[](draws.length);
    uint256 counter = 0;
    for (uint256 i = 0; i < draws.length; i++) {
      _draws[counter] = draws[i];
      counter = counter.add(1);
    }
    return _draws;
  }

  function _getDraw(uint256 _drawId) external view returns (Draw memory) {
    return draws[_drawId];
  }

  function _getCurrentDraw() external view returns (Draw memory) {
    return draws[draws.length.sub(1)];
  }
}
