// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Transactions {
    // simple number type variable to hold the number of transactions in the contract
    uint256 transactionCount;

    // an event is something that you emit 
    event Transfer(address from, address receiver, uint amount, string message, uint256 timestamp, string keyword);

    // the transaction that is carried out
    struct TransferStruct {
        address sender;
        address receiver;
        uint amount;
        string message;
        uint256 timestamp;
        string keyword;
    }

    // an array of objects of type of struct as defined above
    TransferStruct[] transactions;

    // visibility:public means anyone can call this function on the contract
    // does not return anything
    // the address is a blockchain address which can receive payments
    // the messsage is a string that is contained in the memory of the transactions
    function addToBlockchain(address payable receiver, uint amount, string memory message, string memory keyword) public {
        transactionCount += 1;

        // block.timestamp is the timestamp of the block through which this transaction came into the blockchain
        transactions.push(TransferStruct(msg.sender, receiver, amount, message, block.timestamp, keyword));

        // emit the transaction message to the blockchain
        emit Transfer(msg.sender, receiver, amount, message, block.timestamp, keyword);
    }

    // the function has public visibility but only for viewing
    // the function will return an array of structs read from memory
    function getAllTransactions() public view returns (TransferStruct[] memory) {
        return transactions;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactionCount;
    }


}
