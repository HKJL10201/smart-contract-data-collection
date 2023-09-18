// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract Transaction {
uint256 transactionCount;
event Transfer (address from, address receiver, uint amount, string message, uint256 timestamp, string keyword);
//property of transaction // Object // structure 
struct TransferStruct{
address sender;
address receiver;
uint amount;
string message; 
uint256 timestamp; 
string keyword;
}
// array of transation // liste of trnsaction 
TransferStruct [] transactions;

function addToBlockchain (address payable reciever , uint amount, string memory message, string memory keyword ) public {
 transactionCount++;
 //store transaction
 transactions.push(TransferStruct(msg.sender, reciever, amount , message, block.timestamp, keyword));
//making actually the transfer amount 
 emit Transfer(msg.sender, reciever, amount , message, block.timestamp, keyword);
}


function getAllTransactions() public view returns (TransferStruct[] memory) {
 return transactions;
}


function getTransactionCount() public view returns (uint256) {
 return transactionCount;
}
}