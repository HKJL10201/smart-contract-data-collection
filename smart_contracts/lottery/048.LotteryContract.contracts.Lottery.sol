// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Lottery {
  address public manager;
  address[] public players;

  event playerEntered(address indexed _from, uint _value);
  event winnerPicked(address indexed winner, uint pot);

  modifier minEther() {
    require(msg.value > .01 ether, "Send more then .01 ether");
    _;
  }

  modifier isManager() {
    require(msg.sender == manager, "Must be manager of contract");
    _;
  }

  constructor () {
    manager = msg.sender;
  }

  // BAD - Anyone can figure out how your random function selects its number and exploit this
  function random() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
  }

  function restartLottery() private {
    // Initiates variable back to a dynamic array of addresses with 0 values
    players = new address[](0);
  }

  function getPlayers() public view returns (address[] memory) {
    return players;
  }

  function enter() public payable minEther {
    players.push(msg.sender);
    emit playerEntered(msg.sender, msg.value);
  }

  function pickWinner() public payable isManager {
    // Get winning player with psuedo random number
    uint index = random() % players.length;
    // Convert winner address into a payable address (Supports ^0.8.0 solidity)
    address payable winner = payable(players[index]);
    // Get current balance of contract
    uint pot = address(this).balance;

    winner.transfer(pot);
    emit winnerPicked(winner, pot);
    restartLottery();
  }
}