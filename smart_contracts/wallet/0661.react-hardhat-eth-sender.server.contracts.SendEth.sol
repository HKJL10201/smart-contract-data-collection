// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./test/ReEntrancyGuard.sol";

error SendEth__NotEnoughBalance();
error SendEth__TransferFailed();
error SendEth__ReceiverNotAllowed();
error SendEth__InvalidAmount();

contract SendEth is ReEntrancyGuard {
  struct Transaction {
    address sender;
    address receiver;
    uint amount;
    string message;
    uint256 datetime;
  }

  event TransferSuccess(address indexed sender, address indexed receiver, uint256 amount, uint timestamp);

  mapping(address => Transaction[]) private s_transactions;

  function transferETH(address payable _receiver, string memory _message) public payable noReentrant {
    if (msg.sender == _receiver || msg.sender == address(0)) {
      revert SendEth__ReceiverNotAllowed();
    }

    if (msg.value <= 0) {
      revert SendEth__InvalidAmount();
    }

    if (msg.sender.balance < msg.value) {
      revert SendEth__NotEnoughBalance();
    }

    Transaction memory newTransaction = Transaction({
      sender: msg.sender,
      receiver: _receiver,
      amount: msg.value,
      message: _message,
      datetime: block.timestamp
    });
    s_transactions[msg.sender].push(newTransaction);
    s_transactions[_receiver].push(newTransaction);

    (bool success, ) = _receiver.call{value: msg.value}("");
    if (!success) {
      revert SendEth__TransferFailed();
    }

    emit TransferSuccess(msg.sender, _receiver, msg.value, block.timestamp);
  }

  function myTransactions() public view returns (Transaction[] memory) {
    return s_transactions[msg.sender];
  }
}
