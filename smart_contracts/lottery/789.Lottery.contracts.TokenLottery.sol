// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./Base/LotteryLogic.sol";
import "./Interfaces/ITokenLottery.sol";

contract TokenLottery is ITokenLottery, BaseLottery, RevenueStream {

  IERC20 public inputToken;

  constructor(string memory _name, uint _frequency, uint _price, uint _odds, IERC20 _inputToken, uint _fee, address _treasury) {
    name = _name;
    frequency = _frequency;
    price = _price;
    odds = _odds;
    fee = _fee;
    treasury = _treasury;
    inputToken = _inputToken;
    startNewRound();
  }

  function enter() public override returns (bool) {
    require (inputToken.balanceOf(_sender()) >= price, "not enough tokens to enter");

    uint toPot = beforeEachEnter();
    _enter(toPot);

    return true;
  }

  function draw() public override returns (bool) {
    require (readyToDraw(), "not enough time has elapsed since last draw");

    beforeEachDraw();
    _draw();

    return true;
  }

  function getPaid() public override returns (bool) {
    require(debtToUser[_sender()] != 0, "you are not owed any money");

    beforeEachPayment();
    uint winnings = _safePay();
    IERC20(inputToken).transfer(_sender(), winnings);

    emit newPayment(_sender(), winnings);
    return true;
  }

  function beforeEachEnter() internal returns (uint) {
    uint amountAfterFee = takeTokenFee(inputToken, price);
    IERC20(inputToken).transferFrom(_sender(), address(this), price);
    return amountAfterFee;
  }

  function beforeEachDraw() internal returns (bool) {
    lottos[currentLotto].lastDraw = _timestamp();
    return true;
  }

  function beforeEachPayment() internal returns (bool) { }

  function viewTokenAddress() public view override returns (address) {
    return address(inputToken);
  }

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
