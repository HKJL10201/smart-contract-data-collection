// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0; //choosing version of solidity we want to use

//contract serves the same purpose as a class
contract Transactions {
    uint256 transactionCount; //going to hold the number of our transactions (uint is an int)

    //type, then variable name
    //an event is a function that will be emitted later
    event Transfer(address from, address receiver, uint amount, string message, uint256 timestamp, string keyword);

    //struct is specifiying an objects properites
    struct TransferStruct {
        address sender;
        address receiver;
        uint amount;
        string message;
        uint256 timestamp;
        string keyword;
    }

    TransferStruct[] transactions;  //transactions variable will be an array of TransferStruct

    //since it is a class you have to specify visability of functions
    //just doing some actions
    function addToBlockChain(address payable receiver, uint amount, string memory message, string memory keyword) public {
        transactionCount += 1;
        //sender is automatically stored inside of the msg class inside of the block chain
        //block.timestamp is the time of that specific block inside of the blockchain
        transactions.push(TransferStruct(msg.sender, receiver, amount, message, block.timestamp, keyword)); //pushing specific transaction inside of the transactions array(TransferStruct)

        emit Transfer(msg.sender, receiver, amount, message, block.timestamp, keyword);
    }
    
    //public view returns means you have to specify what data type the function will return
    function getAllTransactions() public view returns (TransferStruct[] memory) {
        //return transactions;
    }

    function getTransactionCount() public view returns (uint256) {
        
        return transactionCount;
    }
}
