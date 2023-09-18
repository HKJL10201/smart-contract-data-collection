// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
contract Spotify {

    uint256 totalWaves=0;

    struct Wave {
        address waver;
        string message;
        uint256 timestamp;
    }

    event NewWave(address indexed from,uint256 timestamp,string message);

    Wave[] waves;

    constructor(){
        console.log("Ur contract is constructed! ");
    }

    function wave(string memory _message) public {

        totalWaves += 1;
        
        console.log("%s has waved", msg.sender);
        
        waves.push(Wave(msg.sender, _message, block.timestamp));

        emit NewWave(msg.sender, block.timestamp, _message);

    }

    function getAllWaves() public view returns (Wave[] memory){
        return waves;
    }

    function getTotalWaves() public view returns (uint256){
        return totalWaves;
    }

}