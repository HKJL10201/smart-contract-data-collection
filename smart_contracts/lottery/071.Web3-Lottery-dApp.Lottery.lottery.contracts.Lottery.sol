// SPDX-License-Identifier: MIT

// Lottery Smart Contract

pragma solidity ^0.8.0;

// Create Lottery Smart Contract
contract Lottery {

    // Declare players and owner and Lottery ID
    address payable[] public players;
    address public owner;
    uint public lotteryId;

    // Create mapping to allow to record Lottery Winner History
    mapping (uint => address payable) public lotteryHistory;

    // Define Constructor
    constructor() {
        // Get and define owners address
        owner = payable(msg.sender);
        // Set initial lottery ID to 1
        lotteryId = 1;
    }

    // Function that returns winner based on lottery ID
    function getWinnerByLottery(uint lottery) public view returns (address payable) {
        return lotteryHistory[lottery];
    }

    // Function to return contracts balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    // Function to return current lottery's players
    function getPlayers() public view returns (address payable[] memory){
        return players;
    }

    // Function to enter lottery
    function enter() public payable {
        // Require minimum value to enter
        require(msg.value > .01 ether);
        // add address of player entering lottery into players list
        players.push(payable(msg.sender));
    }

    // Function to get pseudo-random number
    function getRandomNumber() public view returns (uint) {
        // Returns result of keccak256 hashing algorith 
        // (hash concactenation of owner adress and block timestamp)
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    // Function to pick winner - apply onlyOwner modifier 
    function pickWinner() public onlyOwner {
        // Determine pseudo-randomly index of winner 
        uint index = getRandomNumber() % players.length;
        // Transfer contracts balance to winners address
        players[index].transfer(address(this).balance);
        // Update lottery history
        lotteryHistory[lotteryId]= players[index];
        // Increment lottery id by 1
        lotteryId++; 
        // Reset state of contract (resets players list) - prepares for next round
        players = new address payable[](0);
    }

    // Create reusable modifier that makes it so only the owner could execute function
    modifier onlyOwner() {
        // Requires that only the owner can execute this function
        require(msg.sender == owner);
        _; // Apply to remainder of code in function
    }
}