// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

//class
contract Transactions{
    uint256 trnsCounter;

    //like function which is publicly visible
    event Transfer(address sender, address receiver, uint amount, uint256 timestamp);
    
    //like object
    struct TransferStruct{
        address sender;
        address receiver;
        uint amount;
        uint256 timestamp;   
    }

    TransferStruct[] transactions;

    function addToBlockchain(address payable receiver, uint amount)public {
        trnsCounter +=1;
        transactions.push(TransferStruct(msg.sender, receiver, amount, block.timestamp));
        emit Transfer(msg.sender, receiver, amount, block.timestamp);


    }
    function getAllTransactions() public view returns (TransferStruct[] memory){
        return transactions;
    }
    function getTransactionCount() public view returns(uint256){
        return trnsCounter;
    }
}