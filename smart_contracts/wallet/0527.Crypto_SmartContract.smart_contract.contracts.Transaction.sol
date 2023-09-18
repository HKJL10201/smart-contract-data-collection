//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Transaction {
    uint256 transactionCount;

    event Transfer(
        address from,
        address receiver,
        uint256 amount,
        string message,
        uint256 timestamp,
        string keyword
    );

    struct TransferStruct {
        address sender;
        address receiver;
        uint256 amount;
        string message;
        uint256 timestamp;
        string keyword;
    }

    TransferStruct[] transaction;

    function addToBlockchain(address payable receiver, uint amount, string memory message, string memory keyword) public {
        transactionCount += 1;
        transaction.push(TransferStruct(msg.sender, receiver, amount, message, block.timestamp, keyword));

        emit Transfer(msg.sender, receiver, amount, message, block.timestamp, keyword);
    }

    function getToBlockchain() public view returns (TransferStruct[] memory) {
        return transaction;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactionCount;
    }
}
