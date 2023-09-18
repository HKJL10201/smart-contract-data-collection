// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Lottery {
    address public manager;
    address payable[] public players;

    constructor() {
      manager = msg.sender;
    }

    function enter() public payable {
      // validates with a minimum amount of ether
      require(msg.value > .01 ether);
      // add sender address to array
      players.push(payable(msg.sender));
    }

    function random() private view returns (uint) {
      return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public restricted {
      uint index = random() % players.length;
      players[index].transfer(address(this).balance);
      // reset the array to length 0
      players = new address payable[](0);
    }

    modifier restricted() {
      // only the manager can call this function
      require(msg.sender == manager);
      _;
    }

    function getPlayers() public view returns (address payable[] memory) {
      return players;
    }
}
