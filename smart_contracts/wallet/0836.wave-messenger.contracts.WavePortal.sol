// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract WaveMessenger{
    uint totalWaves;

    // we'll use this variable to generate random numbers
    uint256 private seed;

    constructor() payable {
        console.log("You looking at a smart contract");

        // setting the initial seed
        seed = (block.timestamp + block.difficulty) % 100;
    }
    

    event NewWave(address indexed from, uint256 timestamp, string message);

    struct Wave {
        address waver; // address of the user who waved
        string message; // the message the user sent
        uint timestamp; // the timestamp when the user waved
    }

    /* Declare a variable that saves an array of structs
        To hold all the waves users send
     */
    
    Wave[] waves;

    /* 
     * This is an address => uint mapping, 
     * meaning I can associate an address with a number!
     * In this case, I'll store the address with the 
     * last time the user waved at us.
     */
    mapping (address => uint) public lastWavedAt;


    function wave(string memory _message) public {
        /* 
         * We need to make sure the current timestamp is 
         * at least 15 minutes bigger than the last timestamp we stored
         */

        require(
            lastWavedAt[msg.sender] + 15 minutes < block.timestamp, 
            "Wait 15 minutes"
        );

        /* 
         * Update the current timestamp we have for the user
         */

        lastWavedAt[msg.sender] = block.timestamp;

        totalWaves += 1;

        console.log("%s has waved with message - %s", msg.sender, _message);

        waves.push(Wave(msg.sender, _message, block.timestamp));

        // Generate a new seed for the user that waves
        seed = (block.difficulty + block.timestamp + seed) % 100;
        console.log("seed: %d", seed);

        // Give a 50% chance that the user wins the price
        if (seed <= 50) {
            console.log("%s won!", msg.sender);
        
            uint256 prizeAmount = 0.0001 ether;

            require(

                // address(this).balance is the balance of the contract itself
                prizeAmount <= address(this).balance,
                "Trying to withdraw more money than the contract has."
            );

            (bool success,) = (msg.sender).call{value: prizeAmount}("");

            require(
                success,
                "Failed to withdraw money from the contract."
            );
        }

        emit NewWave(msg.sender, block.timestamp, _message);

    }

    function getAllWaves() public view returns(Wave[] memory) {
        return waves;
    }

    function getTotalWaves() public view returns(uint) {
        console.log("Wow! A total of %d waves", totalWaves);

        return totalWaves;
    }
}