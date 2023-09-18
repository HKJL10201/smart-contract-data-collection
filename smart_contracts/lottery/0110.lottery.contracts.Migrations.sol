// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <=0.8.10;

contract Migrations {
    address public owner;
    uint256 public last_completed_migration;

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    constructor() {
        owner = msg.sender;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function setCompleted(uint256 completed) public restricted {
        last_completed_migration = completed;
    }
}
