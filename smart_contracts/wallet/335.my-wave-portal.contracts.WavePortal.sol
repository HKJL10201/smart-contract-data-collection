// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract WavePortal {
    uint256 totalWaves;
    uint256 private seed;

    event NewWave(address indexed from, uint256 timestamp, string message);

    struct Wave {
        address waver; // The address of the user who waved.
        string message; // The message user has sent.
        uint256 timestamp; // The timestamp when the user waved.
    }

    Wave[] waves;

    // This is an address => uint mapping, meaning I can associate an address with a number!
    mapping(address => uint256) public lastWavedAt;
    
    constructor() payable {
        console.log("Yehhh, it's a smart contract constructor");
    }

    function wave(string memory _message) public {
        // make sure the current timestamp is at least 15-minutes bigger than the last timestamp we stored
        require(
            lastWavedAt[msg.sender] + 30 seconds < block.timestamp,
            "Must wait 30 seconds before waving again."
        );

        // Update the current timestamp we have for the user
        lastWavedAt[msg.sender] = block.timestamp;

        totalWaves += 1;
        console.log("%s has waved!", msg.sender);

        waves.push(Wave(msg.sender, _message, block.timestamp));

        // Generate a Psuedo random number between 0 and 100         
        uint256 randomNumber = (block.difficulty + block.timestamp + seed) % 100;
        console.log("Random # generated: %s", randomNumber);
        
        // Set the generated, random number as the seed for the next wave
        seed = randomNumber;

        // Give a 50% chance that the user wins the prize.         
        if (randomNumber < 50) {
            console.log("%s won!", msg.sender);

            // The same code we had before to send the prize. 
            uint256 prizeAmount = 0.0001 ether;
            require(
                prizeAmount <= address(this).balance,
                "Trying to withdraw more money than the contract has."
            );
            (bool success, ) = (msg.sender).call{value: prizeAmount}("");
            require(success, "Failed to withdraw money from contract.");
        }

        emit NewWave(msg.sender, block.timestamp, _message); 
    }

    function getAllWaves() public view returns (Wave[] memory) {
        return waves;
    }

    function getTotalWaves() public view returns (uint256) {
        console.log("We have %d total waves!", totalWaves);
        return totalWaves;
    }
}