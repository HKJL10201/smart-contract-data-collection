//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Lottery {
    // State & Storage Variables
    address public owner;
    address payable[] public players;
    address[] public winners;
    uint public lotteryId;

    // Constructor: runs when contract is deployed
    constructor() {
        owner = msg.sender;
        lotteryId = 0;
    }

    // Enter lottery function
    function enter() public payable {
        require(msg.value >= 0.1 ether);
        players.push(payable(msg.sender));
    }

    // Get players
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    // Get Balance
    function getBalance() public view returns (uint) {
        // Solidity works in WEI
        return address(this).balance;
    }

    // Get Lottery Id
    function getLotteryId() public view returns (uint) {
        return lotteryId;
    }

    // Get random number (helper function for picking winner)
    function getRandomNumber() public view returns (uint) {
        // Number generated is psuedo-random, Use chainlink VRF to ensure no hacks
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    // Pick winner function
    function pickWinner() public {
        require(msg.sender == owner);
        uint randomIndex = getRandomNumber() % players.length;
        players[randomIndex].transfer(address(this).balance);
        winners.push(players[randomIndex]);
        lotteryId++;

        // Clear the players
        players = new address payable[](0);
    }

    // Get Winners function
    function getWinners() public view returns (address[] memory) {
        return winners;
    }
}