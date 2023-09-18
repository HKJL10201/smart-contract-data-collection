// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILottery {
  function deposit() external payable;
  function pickWinner() external;
  function checkLotteryBalance() view external returns (uint256);
  function checkWinnerBalance() view external returns (uint256);
  function checkNoOfPlayers() view external returns(uint);
}