// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract SampleUnits {
    modifier betweenOneAndTwoEth() {
        require(msg.value >= 1e18 && msg.value <= 2e18); // Another way of writing these large numbers is using 1e18 and 2e18, e means ether and 18 stands for number of zeroes.
        _;
    } 

    uint runUntilTimestamp;
    uint startTimestamp;

    constructor(uint startInDays){
        startTimestamp = block.timestamp + (startInDays * 1 days);
        runUntilTimestamp = startTimestamp + (7 days); // It means 7 days.
    }
}