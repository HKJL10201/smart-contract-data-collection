//SPDX-License-Identifier: CC0
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Billboard {
    bytes32 public billboardHash;
    uint256 public leaseExpiry;
    uint256 public dailyRent;
    address payable public owner;

    constructor(uint256 initDailyRent) {
        owner = payable(msg.sender);
        dailyRent = initDailyRent;
    }

    function setOwner(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setDailyRent(uint256 newDailyRent) public onlyOwner {
        dailyRent = newDailyRent;
    }

    function rent(
        bytes32 newBillboardHash,
        uint256 expectedDailyRent
    ) public payable {
        // Without this the owner might change the rent and the client might
        // pay the wrong price.
        require(dailyRent == expectedDailyRent);

        // Don't overwrite previous billboard until its lease has expired.
        require(block.timestamp >= leaseExpiry);

        uint256 duration = msg.value * 86400 / dailyRent;
        require(duration > 0);
        billboardHash = newBillboardHash;
        leaseExpiry = block.timestamp + duration;

        owner.transfer(msg.value);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}
