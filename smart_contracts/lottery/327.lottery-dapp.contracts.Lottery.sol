// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Lottery {
    //State / Storage Variables
    address public owner;
    address payable[] public players;
    address[] public winners;
    uint public lotteryId;

    constructor() {
        owner = msg.sender;
        lotteryId = 0;
    }

    // Participate in the lottery
    function enter() public payable {
        require(msg.value >= 0.1 ether);
        players.push(payable(msg.sender));
    }

    //Get Players
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    } 

    //Get Balance
    function getBalance() public view returns (uint) {
        //Solidity works in WEI
        return address(this).balance;
    }

    //Get Lottery ID
    function getLotteryId() public view returns (uint) {
        return lotteryId;
    }

    //Get random number (helper function for picking winner)
    function getRandomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    //Pick Winner
    function pickWinner() public {
        require(msg.sender == owner);
        uint randomIndex = getRandomNumber() % players.length;
        players[randomIndex].transfer(address(this).balance);
        winners.push(players[randomIndex]);
        lotteryId++;

        players = new address payable[](0);
    }

    //Get Winners
    function getWinners() public view returns(address[] memory){
        return winners;
    }
}