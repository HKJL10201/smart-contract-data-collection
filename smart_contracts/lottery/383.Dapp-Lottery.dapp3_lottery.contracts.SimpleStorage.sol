// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Lottery{
  uint public lotteryId;
  uint public count;
  address[10] public perticipants;
  address public first;

  
  receive()external payable{}
  function random()private view returns(uint){
      return uint(keccak256(abi.encodePacked(block.prevrandao,block.timestamp,perticipants.length))); 
    }
  function winner()private{
    uint a=random()%10;
    first=perticipants[a];
    payable(first).transfer(10 ether);
  }
  function buy()external payable{
    
    require(msg.value==1 ether);
    uint t=count;
    perticipants[t++]=msg.sender;
    count=t;
    if(t==10){
        winner();
    count=0;
    address[10] memory add;
    perticipants=add;
    ++lotteryId;
  }
  }

}