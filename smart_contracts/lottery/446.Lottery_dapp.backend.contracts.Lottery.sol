// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract Lottery {
    //State / Storage Variables
    address public owner;
    address payable[] public players;
    address[] public winners;
    uint public lotteryID;

    //Constructor 
    constructor() {
        owner = msg.sender;
        lotteryID = 0;
    }

    //Enter Function
    function enter() public payable {
        require(msg.value >= 0.1 ether);
        players.push(payable(msg.sender));
    }

    //Get Players
    function getPlayers() public view returns (address payable[] memory){
        return players;
    }

    // Get balance
    function getBalance() public view returns (uint) {
        // In Wei
        return address(this).balance;
    }

    function getLotteryId() public view returns (uint){
        return lotteryID;
    }

    function getWinners() public view returns (address[] memory) {
        // In Wei
        return winners;
    }

    //Get random number
    function getRandomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    //Pick Winner
    function pickWinner() public {
        require(msg.sender == owner);
        uint randomIndex = getRandomNumber() % players.length;
        players[randomIndex].transfer(address(this).balance);
        winners.push(players[randomIndex]); 
        lotteryID++;
        // Clear the player array.
        players = new address payable[](0);
    }
}