//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Transactions{
    uint256 transactionCount;

    event Tranfer(address from ,address to ,uint amount,string message ,uint256 timeStamp,string keyword);

    struct TransferStruct{
        address from ;
        address to;
        uint amount;
        string message;
        uint256 timestamp;
        string keyword;
    }

    TransferStruct[] transactions;

    function addToBlockChin(address payable reciever ,uint amount,string memory message ,string memory keyword) public{
      transactionCount+=1;
      transactions.push(TransferStruct(msg.sender,reciever,amount,message,block.timestamp,keyword));
      emit  Tranfer(msg.sender,reciever,amount,message,block.timestamp,keyword);
    }

    function getAllTransactions() public view returns (TransferStruct[] memory){
         return transactions;
    }

    function getTransactionCout() public view returns (uint256){
        return transactionCount;
    }
}