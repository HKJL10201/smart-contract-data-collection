// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.25;

//similar to class
contract Lottery {
   address public manager;
   address[] public players;
   
  

   constructor() public  {
       manager = msg.sender;
   }
   
      //dry helper function
  modifier restricted() {
      require(msg.sender == manager);
      //takes the code where its used and sticks it below
      _;
  }
   
  function enter() public payable {
      //enter lottery ; send money in require
      require(msg.value> .01 ether);
      players.push(msg.sender);
  }
  function random() private view returns (uint) {
     //pseudo random
      uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
  }
  function pickWinner() public restricted {
      uint index = random() % players.length;
      address contractAddress= this;
      players[index].transfer(contractAddress.balance);
      //0 for default length
      players =new address[](0);
      
  }
    
    function getPlayers() public view returns(address[]) {
        return players;
    }
}
  