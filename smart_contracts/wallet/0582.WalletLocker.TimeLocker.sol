// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeLock {
    address payable owner;
    uint lockTime = 3 minutes;
    uint startTime;

    modifier onlyBy(address _account) {
        require(msg.sender == _account, "Unauthorized");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
        startTime = block.timestamp;
    }

    receive() external payable {}

    function withdraw() public onlyBy(owner) {
        require((startTime + lockTime) < block.timestamp, "Lock time not reached");
        owner.transfer(address(this).balance);
    }
}
