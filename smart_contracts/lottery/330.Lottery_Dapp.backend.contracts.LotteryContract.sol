// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract LotteryContract {
    address public owner;
    address payable[] public players;
    address[] public winners;
    uint public lotteryId;


    // constructor - this run when the contract is gonna be deployed.
    constructor() {
        owner = msg.sender;
        lotteryId = 0;
    }

    // Enter in the pool
    function enter() public payable  {
        require(msg.value >= 0.1 ether);
        players.push(payable(msg.sender));
    }

    // Get Players
    function getPlayers() view public returns( address payable[] memory) {
        return players;
    }

    // Get Balance of the pool
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // Get Lottery ID
    function getLotteryId() public view returns(uint) {
        return lotteryId;
    }

    // Get Random No
    function getRandomNo() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    // Pick Winner
    function pickWinner() public {
        require(msg.sender == owner);
        uint randomIndex = getRandomNo() % players.length;
        players[randomIndex].transfer(address(this).balance);
        winners.push(players[randomIndex]);
        lotteryId++;

        // this line is for cleaning the players array
        // in javascript you can write let players = [];
        players = new address payable[](0);
    }

    // Show Who Wins
    function getWinners() public view returns(address[] memory) {
        return winners;
    }
    

}   