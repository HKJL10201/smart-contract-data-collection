// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MultiSig {
    address[] public owners;
    uint public transactionCount;
    uint public required;

    struct Transaction {
        address payable destination;
        uint value;
        bool executed;
        bytes data;
    }

    mapping(uint => Transaction) public transactions; // Define a mapping that maps transaction IDs to Transaction structs
    mapping(uint => mapping(address => bool)) public confirmations; //maps the transaction id (uint) to an owner (address) to whether or not they have confirmed the transaction (bool).

    receive() external payable {} //Allows the contract to receive ether

    function executeTransaction(uint transactionId) public {
        require(isConfirmed(transactionId));
        Transaction storage _tx = transactions[transactionId];
        (bool success, ) = _tx.destination.call{value: _tx.value}(_tx.data); // call is a low level function that allows us to send ether to a contract address
        require(success, "Failed to execute transaction"); // if the transaction fails, revert the transaction
        _tx.executed = true; //Once transferred, set boolean to true
    }

    function isConfirmed(uint transactionId) public view returns (bool) {
        return getConfirmationsCount(transactionId) >= required; //Return true if the transaction is confirmed and false if it is not.
    }

    function getConfirmationsCount(
        uint transactionId //Return the number of confirmations for a given transaction.
    ) public view returns (uint) {
        uint count; //Define a variable to store the number of confirmations
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count++;
            }
        }
        return count;
    }

    function isOwner(address addr) private view returns (bool) {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == addr) {
                return true;
            }
        }
        return false; // If the address is not an owner, return false.
    }

    function submitTransaction(
        address payable dest, //Define a function that allows an owner to submit a transaction
        uint value, //Define a function that allows an owner to submit a transaction
        bytes memory data
    ) external {
        uint id = addTransaction(dest, value, data);
        confirmTransaction(id);
    }

    function confirmTransaction(uint transactionId) public {
        require(isOwner(msg.sender));
        confirmations[transactionId][msg.sender] = true; //maps the transaction id (uint) to an owner (address) to whether or not they have confirmed the transaction (bool).
        if (isConfirmed(transactionId)) {
            executeTransaction(transactionId);
        }
    }

    function addTransaction(
        address payable destination,
        uint value,
        bytes memory data
    ) public returns (uint) {
        transactions[transactionCount] = Transaction(
            destination,
            value,
            false,
            data
        ); //Define a mapping that maps transaction IDs to Transaction structs
        transactionCount += 1;
        return transactionCount - 1;
    }

    constructor(address[] memory _owners, uint _confirmations) {
        require(_owners.length > 0);
        require(_confirmations > 0);
        require(_confirmations <= _owners.length);
        owners = _owners;
        required = _confirmations;
    }
}
