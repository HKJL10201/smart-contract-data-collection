// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract WavePortal {
    uint256 totalWaves;
    uint256 totalLoves;
    uint256 private seed;

    constructor() payable {
        console.log("Say Hi and show some Love!");
        seed = (block.timestamp + block.difficulty) % 100;
    }

    mapping(address => uint256) public lastSentLoveAt;

    struct Love {
        address sender; // The address of the user who sent love.
        string message; // The message the user sent.
        uint256 timestamp; // The timestamp when the user sent the message.
    }

    Love[] loves;

    event NewLove(address indexed from, uint256 timestamp, string message, bool success);

    function wave() public {
        totalWaves += 1;
        console.log("%s has waved!", msg.sender);
    }

    function love(string memory _message) public {

        /*
         * Cool down period
         */
        require(
            lastSentLoveAt[msg.sender] + 30 seconds < block.timestamp,
            "Wait for 30s after sending one message please!"
        );

        lastSentLoveAt[msg.sender] = block.timestamp;

        totalLoves += 1;
        console.log("%s has sent love!", msg.sender);

        loves.push(Love(msg.sender, _message, block.timestamp));

        seed = (block.difficulty + block.timestamp + seed) % 100;

        console.log("Random # generated: %d", seed);
        bool success = false;

        /*
         * Give a 50% chance that the user wins the prize.
         */
        if (seed <= 50) {
            console.log("%s won!", msg.sender);
            uint256 prizeAmount = 0.0000001 ether;
            require(
                prizeAmount <= address(this).balance,
                "Trying to withdraw more money than the contract has."
            );
            (success, ) = (msg.sender).call{value: prizeAmount}("");
            require(success, "Failed to withdraw money from contract.");
        }

        emit NewLove(msg.sender, block.timestamp, _message, success);
    }

    function getTotalWaves() public view returns (uint256) {
        console.log("We have %d total waves!", totalWaves);
        return totalWaves;
    }

    function getTotalLoves() public view returns (uint256) {
        console.log("We have %d total loves!", totalLoves);
        return totalLoves;
    }

    function getAllLoves() public view returns (Love[] memory) {
        return loves;
    }

    //Functions used for initialization of values from the prev version of this contract
    function setTotalWaves(uint256 waves) public {
        require(totalWaves == 0, "Cannot bulk-add waves except to initialize");
        totalWaves += waves;
        console.log("We have %d total waves!", totalWaves);
    }

    function setTotalLovesCount(uint256 loveCount) public {
        require(totalLoves == 0, "Cannot bulk-add loves except to initialize");
        totalLoves += loveCount;
        console.log("We have %d total loves!", totalLoves);
    }

    function setTotalLoves(Love[] memory allLoves) public {
        require(loves.length == 0, "Cannot bulk-add loves with message except to initialize");
        uint i;
        for(i = 0; i < allLoves.length; i++){
            loves.push(allLoves[i]);
        }
        console.log("We have %d total loves with messages!", loves.length);
    }

}

