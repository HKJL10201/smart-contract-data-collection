// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IFantomLottery {
  function draw() external returns (bool);
  function enter() external payable returns (bool);
  function getPaid() external returns (bool);

  function viewName() external view returns (string memory);
  function viewFrequency() external view returns (uint);
  function viewPrice() external view returns (uint);
  function viewWinChance() external view returns (uint);
  function viewCurrentLottery() external view returns (uint);
  function viewTicketHolders(bytes32 ticketID) external view returns (address[] memory);
  function viewTicketNumber(bytes32 ticketID) external view returns (uint);
  function viewStartTime(uint lottoNumber) external view returns (uint);
  function viewLastDrawTime(uint lottoNumber) external view returns (uint);
  function viewTotalPot(uint lottoNumber) external view returns (uint);
  function viewWinningTicket(uint lottoNumber) external view returns (bytes32);
  function viewUserTicketList(uint lottoNumber) external view returns (bytes32[] memory);
  function viewWinnings() external view returns (uint);

  function readyToDraw() external view returns (bool);
}
