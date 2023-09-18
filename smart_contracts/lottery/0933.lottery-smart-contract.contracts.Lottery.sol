//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Helper.sol";

contract Lottery {
  error LotteryExpiredError(uint timestamp, uint endTime);

  address public owner;
  address payable[] players;
  uint constant MIN_END_DATE = 60 * 2;
  uint constant MIN_TICKETS = 3;
  uint lotteryId;
  uint totalTickets;
  uint ticketAmount;
  uint public endTime;
  mapping(uint => LotteryRecord) history;

  constructor(uint _totalTickets, uint _ticketAmount, uint _endTime){
    require(_endTime >= MIN_END_DATE, "End Date should be equal to or more than 2 min");
    owner = msg.sender;
    totalTickets = _totalTickets;
    ticketAmount = _ticketAmount;
    endTime = block.timestamp + _endTime;
    lotteryId = 1;
  }

  struct LotteryRecord {
    address payable winner;
    uint amountWon;
    address payable[] players;
  }

  modifier isOwner(){
    require(msg.sender == owner);
    _;
  }

  function getBalance() view public returns(uint){
    return address(this).balance;
  }

  function getPlayers() view public returns(address payable[] memory){
    return players;
  }

  function getWinnerByLotteryId(uint _lotteryId) public view returns (LotteryRecord memory){
    return history[_lotteryId];
  }

  function getLotteryHistory() public view returns (LotteryRecord[] memory){
    LotteryRecord[] memory result = new LotteryRecord[](lotteryId - 1);
    
    for(uint i = 0; i < lotteryId - 1; i++){
      LotteryRecord memory record = history[i+1];
      result[i] = record;
    }
    return result;
  }

  
  function register() public payable {
    require(msg.value > ticketAmount, "Amount too low to purchase ticket");
    require(totalTickets > 0, "Tickets are sold out");
    if(players.length > 1 && block.timestamp > endTime){
      revert LotteryExpiredError(block.timestamp, endTime);
    }else if(block.timestamp > endTime){
      endTime = block.timestamp + MIN_END_DATE;
    }
    

    players.push(payable(msg.sender));
    totalTickets--;
  }

  function pickWinner() public isOwner{
    require(block.timestamp >= endTime, "Lottery end time hasn't reached");

    uint index = Helper.generateRandomNumber(owner) % players.length;
    uint balance = this.getBalance();
    players[index].transfer(balance);

    // start a new lottery and create history record
    history[lotteryId++] = LotteryRecord(players[index], balance, players);
    // clean up players
    players = new address payable[](0);
    endTime = block.timestamp + MIN_END_DATE;
    totalTickets = MIN_TICKETS;
    
  }
}