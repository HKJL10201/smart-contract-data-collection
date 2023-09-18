//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract Lottery {
    // State 
    address public owner;
    address payable[] public players;
    address[] public winners;
    uint public lotteryId;

    constructor(){
        owner = msg.sender;
        lotteryId = 0;
    }
    // Enter Function 
    function enter() public payable { 
        require(msg.value >= 0.1 ether);
        players.push(payable(msg.sender));
    }
    // Get Players

    function getPlayers() view public returns ( address payable[] memory) {
        return players;
    }

    // Get Balance from Pool

    function getBalance() view public returns(uint){
        return address(this).balance;
    }
    function getLotteryId() view public returns(uint){
        return lotteryId;
    }
    function getRandomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    // Pick Winner
    function pickWinner()  public {
        require(msg.sender == owner);
        uint randomIndex = getRandomNumber() % players.length;
        players[randomIndex].transfer(address(this).balance);
        winners.push(players[randomIndex]);
        lotteryId++;

        // Now clear the array in this smart contract

        players = new address payable[](0);
    }
    // Winner find

    function getWinner() view public returns(address[] memory){
        return winners;
    }


}