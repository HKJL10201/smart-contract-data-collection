// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Lottery {
    //State / Storage variable
    address public owner;
    address payable[] public players;
    address[] public winners;
    uint public lotteryId;

    //Constructor - this runs when the contract is deployed.
    constructor() {
        owner = msg.sender;
        lotteryId = 0;

    }

    //Enter function
    function enter() public payable {
        require(msg.value >= 0.1 ether);
        players.push(payable(msg.sender));
    }

    //Get players

    function getPlayers() public view returns (address payable[] memory){
        return players;
    }

    //Get Balance of contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    //Get Lottery Id
    function getLotteryId() public view returns (uint) {
        return lotteryId;
    }

    //Get random number (helper function for picking winner)
    function getRandomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp)));
    }

    // Pick Winner
    function pickWinner() public {
        require(players.length>0, "can't pick winners without participants");
        require(msg.sender == owner);
        uint randomIndex = getRandomNumber() % players.length;
        players[randomIndex].transfer(address(this).balance);
        winners.push(players[randomIndex]);
        lotteryId++;

        //Clear the players array.
        players = new address payable[](0);
    }

    //Get Winners 
    function getWinners() public view returns (address[] memory){
        return winners;
    }

    

        
}