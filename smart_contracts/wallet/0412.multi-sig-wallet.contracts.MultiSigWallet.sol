//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract MultiSigWallet {
    address public owner;
    uint private transactionId;
    uint public constant MIN_SIGNATURES = 2;

    mapping(uint => Transaction) private transactions;
    mapping(address => bool) private owners;
    
    uint[] private pendingTransactions;

    struct Transaction {
        address from;
        address to;
        uint amount;
        uint8 signatureCount;
        mapping(address => bool) signatures;
        uint index;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier validOwner() {
        require(msg.sender == owner || owners[msg.sender], "You are not a valid owner");
        _;
    }

    event DepositFunds(address from, uint amount);
    event WithdrawFunds(address from, uint amount);
    event TransactionCompleted(address from, address to, uint amount, uint transactionId);
    event TransactionCreated(address from, address to, uint amount, uint transactionId);
    event TransactionSigned(address by, uint transactionId);
    event TransactionDeleted(address by, uint transactionId);
    
    constructor() {
        owner = msg.sender;
    }

    function addOwner(address _owner) public onlyOwner {
        owners[_owner] = true;
    }

    function removeOwner(address _owner) public onlyOwner {
        owners[_owner] = false;
    }

    function transferTo(address _to, uint _amount) public validOwner {
        require(address(this).balance >= _amount, "Cannot withdraw that amount");
        Transaction storage transaction = transactions[transactionId];
        transaction.from = msg.sender;
        transaction.to = _to;
        transaction.amount = _amount;
        transaction.index = pendingTransactions.length;
        pendingTransactions.push(transactionId);
        emit TransactionCreated(msg.sender, _to, _amount, transactionId++);
    }

    function getPendingTransactions() public view validOwner returns (uint[] memory) {
        return pendingTransactions;
    }


    function signTransaction(uint _transactionId) public validOwner {
        Transaction storage transaction = transactions[_transactionId];
        require(address(0x0) != transaction.from, "Transaction must exist");
        require(msg.sender != transaction.from, "Creator cannot sign it");
        require(!transaction.signatures[msg.sender], "Transaction already signed");

        transaction.signatures[msg.sender] = true;
        transaction.signatureCount++;

        if (transaction.signatureCount >= MIN_SIGNATURES) {
            require(address(this).balance >= transaction.amount, "Not enough funds");
            emit TransactionCompleted(transaction.from, transaction.to, transaction.amount, _transactionId);
            deleteTransaction(_transactionId);
            payable(transaction.to).transfer(transaction.amount);
        } else {
            emit TransactionSigned(msg.sender, _transactionId);
        }
    }

    function deleteTransaction(uint _transactionId) public validOwner {
        uint indexToDelete = transactions[_transactionId].index;
        if (pendingTransactions.length > 1) {
            uint idToMove = pendingTransactions[pendingTransactions.length-1];
            pendingTransactions[indexToDelete] = idToMove;
            transactions[idToMove].index = indexToDelete; 
        }
        pendingTransactions.pop();
        delete transactions[indexToDelete];
        emit TransactionDeleted(msg.sender, _transactionId);
    }

    receive() external payable {
        emit DepositFunds(msg.sender, msg.value);
    }
}
