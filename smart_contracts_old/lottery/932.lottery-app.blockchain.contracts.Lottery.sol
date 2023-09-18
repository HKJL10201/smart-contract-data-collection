// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

contract Lottery {
  // Type address is like a class that stores data from the accounts, also has methods
  address public manager; // The manager for the lottery, the address who initites the contract
  address[] public players; // Players for the lottery

  constructor() {
    // We have a global variable MSG that stores data from the transaction (sender, value, gasPrice)
    // we get the sender, aka the creator of the contract and set as the manager
    manager = msg.sender;
  }

  // In Solidity we have function modifiers that we can define with some particular aspects
  // Somewhat like decorators
  // Using a modifier we can avoid repetitions
  modifier managerOnly() {
    // Only the lottery manager can pick winners
    // Use require to increase security
    require(msg.sender == manager);
    _;
  }

  function enter() external payable {
    // The require method certifies that you can only execute the rest of the method IF the requirements are met
    require(msg.value > 0.0001 ether); // Value in ether, minimum tax to enter
    
    // Add a player if they send a minimum tax to enter
    players.push(msg.sender);
  }

  // Retrieves the lottery manager
  function getManager() external view returns (address) {
    return manager;
  }
  
  // This method returns all players, not only an index at a time
  function getPlayers() external view returns (address[] memory) {
    return players;
  }

  // ALMOST random number generator, is internal because it can demonstrate the winner ahead of time
  function random() internal view returns (uint) {
    // abi.encodePacked joints given numbers to form a more variable number
    // keccak256 method converts passed params to SHA256 hex number
    // UINT method converts it back to base 10 number
    // block has data from the current block being processed
    // block.timestamp has the time
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
  }

  function pickWinner() external managerOnly {
    // the ramdom large number gets divided by the number of players and the rest of the operation is the index of our winner
    uint index = random() % players.length;
    // each player is an address, one of its methods is `transfer`
    // its is used to transfer values to that address
    address payable player = payable(players[index]);
    player.transfer(address(this).balance); // balance is the current amount of ether our contract has stored
    // after we find out the winner, we need to remove the players so that we can start a new lottery
    players = new address[](0); // no initial values asigned to it
  }
}
