// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/Pausable.sol";

contract SimpleWallet is Pausable {

    address private owner;
    uint256 private depositLimit;
    uint256 private totalDeposits;

    event Deposit(address indexed sender, uint amount);
    event Transfer(address indexed recipient, uint amount);

    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor(uint256 _depositLimit) {
        owner = msg.sender;
        depositLimit = _depositLimit;
    }

    function deposit() public payable whenNotPaused {
        require(msg.value <= depositLimit, "Deposit exceeds limit");
        require(totalDeposits + msg.value <= depositLimit, "Total deposits would exceed limit");
        totalDeposits += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function transfer(address payable _to, uint _amount) public onlyOwner whenNotPaused {
        require(address(this).balance >= _amount, "Insufficient balance");

        bool success = _to.send(_amount);
        require(success, "Transfer failed.");

        emit Transfer(_to, _amount);
    }

    function checkBalance() public view returns (uint) {
        return address(this).balance;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
