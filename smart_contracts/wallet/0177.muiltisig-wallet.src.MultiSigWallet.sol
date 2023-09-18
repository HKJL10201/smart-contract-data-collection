//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";

contract MultiSigWallet {
    using Address for address;

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 confirmations;
    }

    address[] public owners;

    Transaction[] public transactions;

    mapping(address => bool) public isOwner;

    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    event Received(address from, uint256 value, uint256 balance);
    event TransactionConfirmation(address indexed owner, uint256 indexed transactionId);
    event RevokeTransaction(address indexed owner, uint256 indexed transactionId);
    event TransactionProposal(address indexed owner, uint256 indexed transactionId, address indexed to, uint256 value);
    event TransactionDone(address indexed owner, uint256 indexed transactionId, address indexed to, uint256 value);

    constructor(address[] memory initialOwners) {
        owners = initialOwners;
        for (uint256 i = 0; i < initialOwners.length; i++) {
            isOwner[initialOwners[i]] = true;
        }
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not the owner");
        _;
    }

    function proposeTransaction(address to, uint256 value) external onlyOwner {
        transactions.push(Transaction(to, value, false, 0));
        emit TransactionProposal(msg.sender, transactions.length - 1, to, value);
    }

    function confirmTransaction(uint256 index) external onlyOwner {
        Transaction storage transaction = transactions[index];
        transaction.confirmations++;
        isConfirmed[index][msg.sender] = true;
        emit TransactionConfirmation(msg.sender, index);
    }

    function revokeConfirmation(uint256 index) external onlyOwner {
        Transaction storage transaction = transactions[index];
        require(isConfirmed[index][msg.sender], "You didn't confirmed the transaction");
        isConfirmed[index][msg.sender] = false;
        transaction.confirmations--;
        emit RevokeTransaction(msg.sender, index);
    }

    function executeTransaction(uint256 index) external onlyOwner {
        Transaction storage transaction = transactions[index];
        require(!transaction.executed, "Transaction already executed");
        require(transaction.confirmations >= owners.length, "All owners need to confirm");
        transaction.executed = true;
        Address.sendValue(payable(transaction.to), transaction.value);
        emit TransactionDone(msg.sender, index, transaction.to, transaction.value);
    }

    function getTransaction(uint256 index) external view returns (address to, uint256 value, bool executed, uint256 confirmations) {
        Transaction storage transaction = transactions[index];
        return (transaction.to, transaction.value, transaction.executed, transaction.confirmations);
    }

    function transactionsCount() public view returns (uint256) {
        return transactions.length;
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value, address(this).balance);
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value, address(this).balance);
    }
}