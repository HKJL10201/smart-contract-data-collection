// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAdmin {
    function transferOwnership(address newOwner) external;
}

contract Admin is IAdmin {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}
