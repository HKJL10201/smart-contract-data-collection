// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract WavePortal {
    uint256 totalWaves;
    uint256 prizeAmount;
    uint256 seed;
    
    event NewWave(address indexed from, uint256 timestamp, string message);
    event Win(bool check);

    struct Wave {
        address waver;
        string message;
        uint256 timestamp;
    }

    Wave[] waves;

    mapping(address => uint256) lastWaved;

    constructor() payable {
        console.log("Yo yo, I am a contract and I am smart");
        prizeAmount = 0.0001 ether;
        seed = (block.difficulty + block.timestamp) % 100;
    }

    function wave(string memory _message) public {
        require(
            lastWaved[msg.sender] + 15 seconds < block.timestamp,
            "You have waved recently, please wait at least 15 seconds after last waved"
        );
        lastWaved[msg.sender] = block.timestamp;

        totalWaves+=1;
        console.log("%s has waved! /w message %s", msg.sender, _message);
        waves.push(Wave(msg.sender, _message, block.timestamp));
        emit NewWave(msg.sender, block.timestamp, _message);
        
        seed = (block.difficulty + block.timestamp + seed) % 100;
        console.log("Seed generated #: ", seed);

        if (seed <= 50) {
            require(prizeAmount <= address(this).balance, 
            "Contract does not have enough money to withdraw!");

            (bool success, ) = (msg.sender).call{value: prizeAmount}("");
            require(success, "Failed to withdraw money from contract.");
        }

        emit Win(seed<=50);
    }

    function getAllWavesCount() public view returns (uint256) {
        return waves.length;
    }

    function getAllWaves() public view returns (Wave[] memory) {
        return waves;
    }

    function getTotalWaves() public view returns (uint256) {
        console.log("We have %s total waves!", totalWaves);
        return totalWaves;
    }
}