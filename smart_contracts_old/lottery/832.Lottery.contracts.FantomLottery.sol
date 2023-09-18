// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./Base/LotteryLogic.sol";
import "./Interfaces/IFantomLottery.sol";
import "@openzeppelin/contracts/Security/ReentrancyGuard.sol";

contract FantomLottery is IFantomLottery, BaseLottery, RevenueStream, ReentrancyGuard {

  constructor(string memory _name, uint _frequency, uint _price, uint _odds, uint _fee, address _treasury) {
    name = _name;
    frequency = _frequency;
    price = _price;
    odds = _odds;
    fee = _fee;
    treasury = _treasury;
    startNewRound();
  }

  function enter() public override payable nonReentrant returns (bool) {
    require (msg.value == price, "enter: invalid token amount");

    uint toPot = beforeEachEnter();
    _enter(toPot);

    return true;
  }

  function draw() public override nonReentrant returns (bool) {
    require (readyToDraw(), "draw: too soon to draw");

    beforeEachDraw();
    _draw();

    return true;
  }

  function getPaid() public override nonReentrant returns (bool) {
    require(debtToUser[_sender()] != 0, "getPaid: nothing to claim");

    beforeEachPayment();
    uint winnings = _safePay();
    payable(_sender()).transfer(winnings);

    return true;
  }

  /*
  + Hooks
  */

  function beforeEachEnter() internal returns (uint) {
    uint amountAfterFee = takeFantomFee(price);
    return amountAfterFee;
  }

  function beforeEachDraw() internal returns (bool) {
    lottos[currentLotto].lastDraw = _timestamp();
    return true;
  }

  function beforeEachPayment() internal returns (bool) { }

  /*
  + View Functions
  */

  function viewName() public view override returns (string memory) {
    return name;
  }

  function viewFrequency() public view override returns (uint) {
    return frequency;
  }

  function viewPrice() public view override returns (uint) {
    return price;
  }

  function viewWinChance() public view override returns (uint) {
    return (odds);
  }

  function viewCurrentLottery() public view override returns (uint) {
    return currentLotto;
  }

  function viewTicketHolders(bytes32 ticketID) public view override returns (address[] memory) {
    return tickets[ticketID].owners;
  }

  function viewTicketNumber(bytes32 ticketID) public view override returns (uint) {
    return tickets[ticketID].ticketNumber;
  }

  function viewStartTime(uint lottoNumber) public view override returns (uint) {
    return lottos[lottoNumber].startTime;
  }

  function viewLastDrawTime(uint lottoNumber) public view override returns (uint) {
    return lottos[lottoNumber].lastDraw;
  }

  function viewTotalPot(uint lottoNumber) public view override returns (uint) {
    return lottos[lottoNumber].totalPot;
  }

  function viewWinningTicket(uint lottoNumber) public view override returns (bytes32) {
    return lottos[lottoNumber].winningTicket;
  }

  function viewUserTicketList(uint lottoNumber) public view override returns (bytes32[] memory) {
    return userTickets[lottoNumber][msg.sender];
  }

  function viewWinnings() public view override returns (uint) {
    return debtToUser[_sender()];
  }

  function readyToDraw() public view override returns (bool) {
    return (_timestamp() - lottos[currentLotto].lastDraw >= frequency);
  }
}
