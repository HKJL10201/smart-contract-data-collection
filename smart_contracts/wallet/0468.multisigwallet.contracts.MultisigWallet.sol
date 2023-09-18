// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "hardhat/console.sol"; // used in testing chains

/**
 * @title Simple Multisig Wallet Contract
 * @author Al-Qa'qa'
 * @notice This contract works like a sinple mutlisig wallet
 */
contract MultisigWallet {
  event Deposit(address indexed sender, uint256 amount);
  event Submit(uint256 indexed txId);
  event Approve(address indexed owner, uint256 indexed txId);
  event Revoke(address indexed owner, uint256 indexed txId);
  event Execute(uint256 indexed txId);

  struct Transaction {
    address to;
    uint256 value;
    bytes data;
    bool executed;
  }

  address[] public owners; // the owners of the contract
  mapping(address => bool) public isOwner; // if the address is owner
  uint256 public required; // how many requires needed

  Transaction[] public transactions; // all transactions occuars in our wallet

  mapping(uint256 => mapping(address => bool)) public approved; // store the tx approvals by owner

  modifier onlyOwner() {
    require(isOwner[msg.sender], "You are not owner");
    _;
  }

  modifier txExists(uint256 _txId) {
    require(_txId < transactions.length, "tx does not existed");
    _;
  }

  modifier notApproved(uint256 _txId) {
    require(!approved[_txId][msg.sender], "tx already approved");
    _;
  }

  modifier notExecuted(uint256 _txId) {
    require(!transactions[_txId].executed, "tx already executed");
    _;
  }

  /**
   * When making the our wallet we should provide an array of address that represent the owners of this contract
   * that have access to this wallet.
   * We should provide the minimun number of approvals of owners needed in order to execute a transaction.
   *
   * @param _owners Array of owners addresses of the contract
   * @param _required the number of addresses needed to approve for a transaction in order ro execute
   */
  constructor(address[] memory _owners, uint256 _required) {
    require(_owners.length > 0, "Owners required");
    require(
      _required > 0 && _required <= _owners.length,
      "Invalid required number of owners"
    );

    console.log("Check passed successfully");

    for (uint256 i; i < _owners.length; i++) {
      address owner = _owners[i];

      require(owner != address(0), "Invalid owner"); // check the owner is not address zero
      require(!isOwner[owner], "owner is not unique"); // check the owner is not already existed
      isOwner[owner] = true; // active owner
      owners.push(owner); // add the owner address to owners array
      console.log("New owner added: ", owner);
    }

    required = _required;
    console.log("Finished constructor");
  }

  /**
   * Handle receiving ETH from external wallets
   */
  receive() external payable {
    emit Deposit(msg.sender, msg.value);
  }

  /**
   * Sumbit new tx into our multisig wallet
   *
   * @param _to address that will receive the transaction
   * @param _value the amount of ETH that will transfered to the receiver
   * @param _data data passed with the tx
   */
  function submit(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external onlyOwner {
    transactions.push(Transaction(_to, _value, _data, false));
    emit Submit(transactions.length - 1); // the index of the last element of transactions array

    // This logic is weak since you should approve the address that submited the tx
    // Its better to approve the address that sumbitted
  }

  /**
   * Approve the transaction already sumbitted, but it is waiting approvals to be executed
   *
   * @param _txId transaction index in transaction array
   */
  function approve(
    uint256 _txId
  ) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId) {
    approved[_txId][msg.sender] = true;
    emit Approve(msg.sender, _txId);
  }

  /**
   * execute the transaction and send ETH and data of the transaction to the receiver address
   *
   * @param _txId transaction index in transactions
   */
  function execute(uint256 _txId) external txExists(_txId) notExecuted(_txId) {
    require(_getApprovalCount(_txId) >= required, "approvals < required");
    Transaction storage transaction = transactions[_txId];
    transaction.executed = true;

    (bool success, ) = transaction.to.call{value: transaction.value}(
      transaction.data
    );
    require(success, "Transaction failed");

    emit Execute(_txId);
  }

  /**
   * Revoke that approval of the owner address (remove the approval)
   *
   * @param _txId transaction index in transactions
   */
  function revoke(
    uint256 _txId
  ) external onlyOwner txExists(_txId) notExecuted(_txId) {
    require(approved[_txId][msg.sender], "tx not approved");
    approved[_txId][msg.sender] = false;
    emit Revoke(msg.sender, _txId);

    // You are not handle deleting the transaction which is not a good thing
    // storing in array has its drawbacks too
  }

  /**
   * Get the number of approvals if the transaction id
   *
   * @param _txId transaction index in transactions
   */
  function _getApprovalCount(uint _txId) private view returns (uint256 count) {
    for (uint i; i < owners.length; i++) {
      if (approved[_txId][owners[i]]) {
        count++;
      }
    }
  }
}
