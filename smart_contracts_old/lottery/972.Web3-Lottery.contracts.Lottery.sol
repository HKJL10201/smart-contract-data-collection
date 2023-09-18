// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Lottery {
    address public manager;
    address[] public players;
    
    constructor() {
        manager = msg.sender;
    }
    
    /**
        Function that allows people to enter the 'lottery' but a min contribution of .01 ether is required
     */
    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    /**
        Pseudo random function that returns the winner of the lottery from the addresses that entered.
        Keep in mind that Solidity doesn't have absolute randomness hence why i called this PSEUDO random
        Meaning someone can cheat to make themselves the winner if they know the below hecne why a legit 
        lottery contract to replace national lottery is not feasible just yet!
     */
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
    
    /**
        Calculates the index of the winner using the Random function by using modulo which will always 
        return a number between 0  and n-1 where n is the number of players. We then send the total balance
        of the contract to that address and clear our players array! 
     */
    function pickWinner() public onlyManager {
        uint index = random() % players.length;
        payable(players[index]).transfer(address(this).balance);
        players = new address[](0);
    }
    
    /**
        Modifier which only allows the creator of the contract (manager) to perform certain actions
        For example only the manager should pick a winner! 
     */
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    
    /**
        Returns the list of players (addresses) that have entered the lo
     */
    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}   