// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {

  enum State {
    IDLE,
    BETTING
  }

  State public currentState = State.IDLE;
  address payable[] public players;

  uint public betCount;
  uint public betSize;
  uint public houseFee;
  address public admin;

  constructor(uint _houseFee) {
    require(_houseFee >1 && _houseFee < 10, 'fee should be reasonable');
    admin = msg.sender;
    houseFee = _houseFee;
  }

  modifier isState(State _state) {
    require(currentState == _state,'current state does not allow this');
    _;
  }

  modifier onlyAdmin() {
    require(msg.sender ==admin, 'only admin can do this');
    _;
  }

  function createBet(uint _betCount, uint _betSize) external payable onlyAdmin() isState(State.IDLE) {
    betCount = _betCount;
    betSize = _betSize;
    currentState = State.BETTING;
  }

  function bet() external payable isState(State.BETTING) {
    require(msg.value == betSize, 'can only bet the exact size');
    players.push(payable(msg.sender));
    
    if(players.length == betCount){
      //pick a winner
      uint winnerId = _randomGen(players.length);
      //send the money to wallet
      players[winnerId].transfer((betSize*betCount) * (100-houseFee) / 100);
      //reset state to IDLE
      currentState = State.IDLE;
      delete players;
      //clean up
    }

  }

  function _randomGen(uint _modulo) view private returns(uint){
    return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,block.number))) % _modulo;
  }

  function cancel() external onlyAdmin() isState(State.BETTING) {
    currentState = State.IDLE;
    for (uint i=0;i<players.length;i++){
      players[i].transfer(betSize);
    }
    delete players;
  }


}
