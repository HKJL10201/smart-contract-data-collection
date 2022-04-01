// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract WavePortal {
		uint256 totalWaves;

    constructor() {
        console.log("constructor: Yo zer0kool, I am a contract and I am smart");
    }
		
		function wave() public {
        totalWaves += 1;
        console.log("%s has waved!", msg.sender);
    }

    function getTotalWaves() public view returns (uint256) {
			if (totalWaves > 0){
        	console.log("We have %d total waves!", totalWaves);
				}
        return totalWaves;
    }
}