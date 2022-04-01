// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";

//define the contract here
contract WavePortal {
    uint256 totalWaves;

    constructor() {
        console.log("My first smart contract!");
    }

    function wave() public {
        totalWaves += 1; //adds a wave count each tiime someone waves
        //totalWaves is initialized to 0 automatically
        console.log("%s says hi!", msg.sender);
    }

    function getTotalWaves() public view returns (uint256) {
        console.log("We have %d total waves", totalWaves);
        return totalWaves;
    }
}
