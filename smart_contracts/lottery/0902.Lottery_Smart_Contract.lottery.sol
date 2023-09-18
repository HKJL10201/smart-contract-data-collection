// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract lottery{
    // entities=> manager,player,winner
  address public manager;
  address payable[] public players;
  address payable public winner;

  constructor(){
      manager=msg.sender;
  }
  
  function participate() public payable{
      require(msg.value==1 ether,"please pay 1 ether only");
      players.push(payable(msg.sender));
  }

  function getbalance() public view returns(uint){
      require(manager==msg.sender,"you are not manager");
      return address(this).balance;
  }

  function random() internal view returns(uint){
      return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
  }

  function pickWinner() public{
      require(manager==msg.sender,"you are not the manager");
      require(players.length>=3,"players are less than three");

      uint r=random();
      uint index=r%players.length;
      winner=players[index];
      winner.transfer(getbalance());
      players=new address payable[](0); // this will initialize the players array back to zero
      

  }
}