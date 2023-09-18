// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract lottery {
  address public manager;
  address payable[] public players;
  constructor() {
    manager = msg.sender;
  }

  function enter() public payable {
    require(msg.value > 0.01 ether, 
    "A minimum payment of .01 ether must be sent to enter the lottery");
    players.push(payable(msg.sender));
  }

  function random() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp , players)));
  }

  function pickWinner() public onlyManager {
    uint index = random() % players.length;
    players[index].transfer(address(this).balance);
    players = new address payable[](0);
  }

  function getPlayers() public view returns (address payable[] memory) {
    return players;
  }

  modifier onlyManager() {
    require(msg.sender == manager, "Only owner can call this function.");
    _;
  }

}
