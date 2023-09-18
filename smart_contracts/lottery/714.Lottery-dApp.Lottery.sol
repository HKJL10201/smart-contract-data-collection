// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract Lottery {
    // State / Storage Variable
    address public owner; // Creating the address of owner.
    address payable[] public players; // Creating an address of all the players.
    address[] public winners; // Creating an address of winner.
    uint public lotteryId; // Creating a Lottery ID.

    // Constructor - this runs when the contract is deployed.

    constructor() {
        owner = msg.sender;
        lotteryId = 0;
    }

    // Creating functions

    // Enter function
    function enter() public payable {
        require(msg.value >= 0.1 ether);
        players.push(payable(msg.sender)); // Adding it to the players array. It is payable so that we can pay the sender all the amount later. If we didn't have payable in this line then we wouldnt be able to require it.
    }

    // Get Players
    function getPlayers() public view returns (address payable[] memory) {
        return players; // The more number of players we add in it, it creates an array of them. The enter button in remix adds these players. When we repeatedly click on getPlayers button then (from different accounts) then it creates an array of all the account addresses.
    }

    // Get Balance
    function getBalance() public view returns (uint) {
        return address(this).balance; // Returns the address of the balance. Returns the address of this particular contract, i.e the amount of money which is present at the moment in the pool, with the help of getBalance button.
    }

    // Getting the lottery ID
    function getLotterId() public view returns (uint) {
        return lotteryId; // At present it would give output as 0 because in the constructor function we gave it to be 0.
    }

    // Getting a random number (helper function for picking a winner)
    function getRandomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp))); // This is the most secure way of generating a random number because by this no hacker will be able to trace this. keccak256 is an algorithm.
    } // This keccak256 algorithm is amazing as it generates a number which is very large. Therefore, extremely tough to guess.

    // Picking the Winner
    function pickWinner() public {
        // Only the owner of contract can pick the winner, i.e whenever you're testing make sure you've selected the the owner account as the primary one.
        require(msg.sender == owner);
        uint randomIndex = getRandomNumber() % players.length; // It will give a random person from the number of people in the pool. For eg - Out of [A, B, C] it will give either 0, 1 or 2.
        players[randomIndex].transfer(address(this).balance); // It will transfer the money to the randomly selected person.
        winners.push(players[randomIndex]);
        lotteryId++;

        // Clearing the players array. ['player1', 'player2'] => []
        players = new address payable[](0);
    }

    // Get winners
    function getWinners() public view returns (address[] memory) {
        return winners;
    }
}
