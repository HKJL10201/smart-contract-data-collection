//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract SharedWallet is Ownable {
    mapping(address => uint256) allowances;

    // Events

    event MoneySent(
        address indexed initiator,
        address indexed receiver,
        uint256 amount
    );

    event AllowanceAdded(
        address indexed initiator,
        address indexed member,
        uint256 amount
    );

    event AllowanceReduced(
        address indexed initiator,
        address indexed member,
        uint256 amount
    );

    constructor() {
        console.log("Contract initialized by:", msg.sender);
    }

    // Ownership

    function isOwner() internal view returns (bool) {
        return owner() == msg.sender;
    }

    // Allowance

    modifier allowedToWithdraw(uint256 amount) {
        require(
            isOwner() || allowances[msg.sender] >= amount,
            "User can't withdraw funds: Not contract owner or not allowed such amount"
        );
        _;
    }

    function addAllowance(address member, uint256 amount) public onlyOwner {
        allowances[member] += amount;
        emit AllowanceAdded(msg.sender, member, amount);
    }

    function reduceAllowance(address member, uint256 amount) public onlyOwner {
        allowances[member] -= amount;
        emit AllowanceReduced(msg.sender, member, amount);
    }

    function getMemberAllowance(address member) public view returns (uint256) {
        return allowances[member];
    }

    // Balance & Transfer

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawFundsFromContract(address payable to, uint256 amount)
        public
        allowedToWithdraw(amount)
    {
        require(
            amount <= address(this).balance,
            "Contract doesn't own enough funds"
        );
        if (!isOwner()) {
            allowances[msg.sender] -= amount;
        }

        (bool success, ) = to.call{value: amount}("");
        require(success == true, "Transfer failed");
        emit MoneySent(msg.sender, to, amount);
    }

    receive() external payable {}

    fallback() external {}
}
