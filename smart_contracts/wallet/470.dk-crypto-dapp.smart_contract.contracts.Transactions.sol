// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
// The word "pragma" tells the compiler which version of Solidity to use.

// The contract serves a purpose of a class in object orinted programming languages. 
contract Transactions {
    uint256 transactionCount;
// In Javascript you can declare a variable such as the number 5 and later on redeclare that variable to the string '5'.
// In most other programming languages, including Solidity, you can't do that because they're statically typed.
// Here transactionCount is an integer, a simple number variable that holds the number of transactions.

    event Transfer(address from, address receiver, uint amount, string message, uint256 timestamp, string keyword);
// 'event' is like a function that we will emit (or call) later on.
// It will accepts parameters (with the first word as its type and the second as its name).

// 'struct' is similar to an object.
// Here we're not declaring an object but specifying what properties it has and their types.
    struct TransferStruct {
        address sender;
        address receiver;
        uint amount;
        string message;
        uint256 timestamp;
        string keyword;
    }

    TransferStruct[] transactions;
    // We also want to define an array of transactions to store them.
    // Here we're declaring an array variable 'transactions' made of TransferStruct, an array of objects.

    function addToBlockchain(address payable receiver, uint amount, string memory message, string memory keyword) public {
    // Since this is a class, the visibility of the funcion needs to be defined.
    // We defined as 'public' so everyone can access the function. 
    
        transactionCount += 1;
        transactions.push(TransferStruct(msg.sender, receiver, amount, message, block.timestamp, keyword));
        // The sender is already in the object called 'msg'.
        // You get 'msg' whenever you call a function in the blockchain, it'll already be there.
        // 'block' is also available when you call a function on the blockchain.
        // So far we're adding the transactoin to the list of all transactions, but not making the transfer.

        emit Transfer(msg.sender, receiver, amount, message, block.timestamp, keyword);
        // Now we're making the transfer with 'emit'.
    }

    // Statically typed programming languages sets rules that defends us from ourselves from making mistakes and creating bugs.
    // Here we know that getTransactionCount is a function that must return the transaction count, which is a number.
    // getAllTranscations will return an array of objects, and addToBlockchain doesn't return anything, it just does some actions.
    function getAllTransactions() public view returns (TransferStruct[] memory) {
        return transactions;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactionCount;
    }
}

// Our ethereum Solidity smart contract transfers ETH amounts and stores the transactions that come through it.  