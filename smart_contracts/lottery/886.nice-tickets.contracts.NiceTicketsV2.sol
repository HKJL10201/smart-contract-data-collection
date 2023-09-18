//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.9;

import "@openzeppelin/upgrades-core/contracts/Initializable.sol";

contract NiceTicketsV2 is Initializable {

  address owner;

  uint public firstPrizeMaxAmount;
  uint public secondPrizeMaxAmount;

  //
  uint public betMinAmount;

  // prize pool
  uint public prizePool;

  // you win event
  event WonTicket(address indexed user, uint indexed lotNumber, uint indexed level, uint amount);
  event LostTicket(address indexed user, uint indexed lotNumber);
  event Test();
  function initialize() initializer public {
    //for constructor content
    firstPrizeMaxAmount = 1000*10**18;//1000ETH 一等奖
    secondPrizeMaxAmount = 10*10**18;//10ETH 二等奖
    betMinAmount = 1*10**18;
  }

  //prize number
  function prizeNumber() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 10000;
  }
  function placeBet(uint _userNumber) public payable{
    require(msg.value == betMinAmount, "invalid bet amount!");
    require(_userNumber > 0 && _userNumber < 10000, "invalid number!");
    prizePool += msg.value;
    uint _prizeNumber = prizeNumber();
    if(_userNumber == _prizeNumber){
      //firstPrize
      uint _winAmount = prizePool > firstPrizeMaxAmount ? firstPrizeMaxAmount:prizePool;
      msg.sender.transfer(_winAmount);
      prizePool-=_winAmount;
      emit WonTicket(msg.sender,_prizeNumber,1,_winAmount);
    }else{
      uint[2] memory _userPatterns = [_userNumber%1000, _userNumber/10];
      uint[2] memory _prizePatterns = [_prizeNumber%1000, _prizeNumber/10];
      bool _isWin = false;
      for(uint i=0;i<_userPatterns.length;i++){
        if(_isWin)break;
        for(uint j=0;j<_prizePatterns.length;j++){
          if(_isWin)break;
          if(_userPatterns[i] == _prizePatterns[j])
            _isWin = true;
        }
      }
      if(_isWin){
        //secondPrize
        uint _winAmount = prizePool > secondPrizeMaxAmount ? secondPrizeMaxAmount:prizePool;
        msg.sender.transfer(_winAmount);
        prizePool-=_winAmount;
        emit WonTicket(msg.sender,_prizeNumber,2,_winAmount);

      }else{
        //no award
        emit LostTicket(msg.sender,_prizeNumber);
      }
    }
  }
}
