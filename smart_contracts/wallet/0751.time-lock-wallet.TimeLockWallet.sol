// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeLockWallet {
    address public owner;
    uint256 public releaseTime;
    uint256 public lockedAmount;

    event Deposited(address indexed sender, uint256 amount);
    event Withdrawn(address indexed sender, uint256 amount);

    constructor(uint256 _releaseTime) {
        require(_releaseTime > block.timestamp, "Release time must be in the future");
        owner = msg.sender;
        releaseTime = _releaseTime;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyAfterRelease() {
        require(block.timestamp >= releaseTime, "Funds are locked until the release time");
        _;
    }

    receive() external payable {
        revert("Do not send Ether directly to this contract");
    }

    function deposit() external payable onlyOwner {
        lockedAmount += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() external onlyOwner onlyAfterRelease {
        uint256 amount = lockedAmount;
        lockedAmount = 0;
        payable(owner).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }
}
