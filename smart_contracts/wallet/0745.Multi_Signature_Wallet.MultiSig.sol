// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MultiSig {
    address[] public owners;
    uint256 public required;
    uint public transactionCount;

    struct Transaction {
      address destination;
      uint256 value;
      bool executed;
      bytes data;
    }
    //store transaction with an id untill confirmed by other members
    mapping(uint => Transaction) public transactions;

    //Nested Mapping of confirmations for a transaction
    mapping(uint => mapping(address => bool)) public confirmations;

    constructor(address[] memory _owners, uint256 _required) {
      require(_owners.length > 0);
      require(_required != 0);
      require(_owners.length >= _required);
      owners = _owners;
      required = _required;
    }

    function addTransaction(address _destination, uint256 _value, bytes memory _data) internal returns(uint) {
      transactions[transactionCount] = Transaction(_destination, _value, false, _data);
      transactionCount++;
      return transactionCount - 1;
    }

    function submitTransaction(address tranAddr, uint value, bytes memory _data) public {
      uint id = addTransaction(tranAddr, value, _data);
      confirmTransaction(id);
    }

    function confirmTransaction(uint transactionId) public {
      require(isOwner(msg.sender));
      confirmations[transactionId][msg.sender] = true;
      if (getConfirmationsCount(transactionId) >= required) {
        executeTransaction(transactionId);
      }
    }

    function getConfirmationsCount(uint transactionId) public view returns(uint) {
      uint count;
      for (uint i = 0; i < owners.length; i++) {
        if (confirmations[transactionId][owners[i]]) {
          count++;
        }
      }
      return count;
    }

    function isOwner(address _addr) public view returns(bool) {
      for (uint i = 0; i < owners.length; i++) {
        if (owners[i] == _addr) {
          return true;
        }
      }
      return false;
    }

    function isConfirmed(uint _transactionId) public view returns(bool) {
      uint transConfirmations = getConfirmationsCount(_transactionId);
      if (transConfirmations >= required) {
        return true;
      }
      return false;
    }

    function executeTransaction(uint transactionId) internal {
      //make sure transaction is confirmed
      require(isConfirmed(transactionId));

      //send the value to the destination address
      Transaction  storage _tx = transactions[transactionId];
      (bool success, ) = _tx.destination.call{ value: _tx.value }(_tx.data);
      require(success, "Failed to execute the transaction");
      _tx.executed = true;
    }

    //function to receive funds from external parties
    receive() external payable {}
}
