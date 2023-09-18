pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import './LotteryClaimer.sol';

contract Lottery is LotteryClaimer {
  using SafeMath for uint256;
  uint256 private delay = 30 seconds;

  event DrawDone();

  constructor(address _LTY) LotteryClaimer(_LTY) {}

  function draw() public returns (bool) {
    bool success = false;
    if (needToDraw()) {
      success = processDraw();
      emit DrawDone();
    }
    return success;
  }

  function nextLotteryAt() public view returns (uint256) {
    return draws[lotteryCount].startedAt.add(delay);
  }

  function needToDraw() public view returns (bool) {
    return block.timestamp.sub(draws[lotteryCount].startedAt) >= delay;
  }

  function setDelay(uint256 _newDelay) external onlyOwner {
    delay = _newDelay;
  }
}
