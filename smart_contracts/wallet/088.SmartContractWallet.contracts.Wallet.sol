//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable {
    mapping(address => uint256) currentDeposits;
    mapping(address => uint256) historialDeposits;

    address[] currentDepositers;
    address[] historialDepositers;

    // Deposit event so we can listen for deposits
    event deposit(address indexed user, uint256 etherAmount);
    event withdraw(address indexed user, uint256 etherAmount);

    constructor() {}

    receive() external payable {
        currentDeposits[msg.sender] += msg.value;
        currentDepositers.push(msg.sender);

        historialDeposits[msg.sender] += msg.value;
        historialDepositers.push(msg.sender);

        emit deposit(msg.sender, msg.value);
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        //Send the money back to the owner
        payable(msg.sender).transfer(balance);
        emit withdraw(msg.sender, balance);

        // Delete all records for current deposits
        resetCurrentBalance();
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getCurrentDeposits(address _address)
        external
        view
        returns (uint256)
    {
        return currentDeposits[_address];
    }

    function getOverallDeposits(address _address)
        external
        view 
        returns(uint256)
    {
        return historialDeposits[_address];
    }

    function resetCurrentBalance() internal onlyOwner {
        for (uint256 i = 0; i < currentDepositers.length; i++) {
            currentDeposits[currentDepositers[i]] = getResetValue();
        }
        // Clean up arrway after for fresh deposits.
        delete currentDepositers;
    }

    function getResetValue() internal pure returns (uint256) {
        return 0;
    }
}
