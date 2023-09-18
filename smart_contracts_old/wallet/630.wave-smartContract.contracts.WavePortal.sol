// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract WavePortal {
    uint256 totalWaves;

    uint private seed;

    event NewWave(address indexed from, uint256 timestamp, string message);

    struct Wave {
        address waver; // address of the user who waved.
        string message; // The message the user sent.
        uint256 timestamp; // The time the user waved.

    }

    Wave[] waves;

    mapping(address => uint256) public lastWavedAt;

    constructor() payable {
        console.log("Yo yo yo, I am a contract and I am smart");
        // set the initial seed to a random value.
        seed =(block.timestamp + block.difficulty) % 100;

    }

    function wave(string memory _message) public {
        // we need to make sure the current timestamp is at least 15-minutes bigger than the last timestamp we stored.
        require(
            lastWavedAt[msg.sender] + 15 minutes < block.timestamp,
            "wait 15m"
        );

        // Update the current timestamp we have for the user.
        lastWavedAt[msg.sender] = block.timestamp;


        totalWaves += 1 ;
        console.log("%s waved w/ message %s!", msg.sender, _message);

        // Store the wave data in the array.
        waves.push(Wave(msg.sender, _message, block.timestamp));


        // generate a new seed for the next user that send a wave
        seed = (seed + block.timestamp + block.difficulty) % 100;

        // console.log("Random # generated: %d", seed);

        //give a 50% chance of user wins the prize
        if(seed<=50){
            console.log("%s won the prize!", msg.sender);

            uint256 prizeAmount = 0.0001 ether;
            require(prizeAmount <= address(this).balance, "Trying to withdraw more than the contract has.");

            (bool success, ) = (msg.sender).call{value: prizeAmount}("");
            require(success, "Failed to withdraw ether to the contract.");
        }

        emit NewWave(msg.sender, block.timestamp, _message);
    }

    // Added function getAllWaves which will return the struct array, waves, to us.
    // This will amke it easy to retrive the waves from our contract from our website!
    function getAllWaves() public view returns (Wave[] memory) {
        return waves;
    }

    function getTotalWaves() public view returns(uint256){
        console.log("We have %d total waves!", totalWaves);
        return totalWaves;
    }
}