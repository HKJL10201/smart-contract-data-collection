// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Queue {

    
    struct Transaction{
        //saving the id of the transaction
        uint256 id;
        //saving the time of the transaction
        uint256 time;
    }

    /// @notice A unique identifier for the Transaction
    mapping(uint256 => Transaction) public exactTransaction;

    /// @notice Storign the contract's owner
    address internal owner;

    /// @notice storing the Transaction's id in the queue
    uint256[] internal queue;

    /// @notice Increasing the id of the Transaction id
    uint256 public queueNum = 0;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }

    /// @notice creating a Transaction struct and storing it
    function addToQue(uint256 _id) external {
        //increase the queue's number
        queueNum++;
        //creating a new instance
        Transaction storage newTransaction = exactTransaction[queueNum];
        //storing the id
        newTransaction.id = _id;
        //storing the time
        newTransaction.time = block.timestamp;
        //add item to the queue
        queue.push(newTransaction.id);
    }

    


}