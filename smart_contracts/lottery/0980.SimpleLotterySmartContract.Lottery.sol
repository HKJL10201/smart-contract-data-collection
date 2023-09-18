// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Lottery {
    address owner;
    address payable[] public  players;
    address[] winners;
    uint256 winnersCount = 0;

    constructor(){
        owner = msg.sender;
    }

    function enterLottery() public payable {
        require(msg.value >= 1 ether, "Entry fee is 1ETH");
        //Here msg.sender is the one that calls this function, not owner
        players.push(payable (msg.sender));
    }

    function generateRandomNumber() public view returns (uint256){
        return uint256(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    function winner() public{
        require(msg.sender == owner, "Only owner can call this method");
        uint256 index = generateRandomNumber() % players.length;

        //add winner to the Winners array
        winners.push(players[index]);
        winnersCount++;

        //Reset the players array to start adding players from starting
        players = new address payable[](0);
    }

    function getLotteryAmount() public view returns (uint256){
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable [] memory){
        return players;
    }

    function getWinners() public view returns(address[] memory){
        return winners;
    }
}