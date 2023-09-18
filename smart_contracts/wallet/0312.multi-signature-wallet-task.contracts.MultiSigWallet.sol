//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract MultiSigWallet {
    event Deposit(address sender, uint256 value);
    event Submit(address sender, uint txId);
    event Approve(address sender, uint txId);
    event Revoke(address sender, uint txId);
    event Execute(uint txId);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;

    uint256 public requiredApprovals;

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approved;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint txId) {
        require(txId < transactions.length);
        _;
    }

    modifier txNotExecuted(uint txId) {
        require(!transactions[txId].executed, "Already executed");
        _;
    }

    modifier txNotApproved(uint txId) {
        require(!approved[txId][msg.sender], "Already approved");
        _;
    }

    constructor(address[] memory _owners, uint256 _requiredApprovals) {
        require(_owners.length > 0, "owners required");
        require(
            _requiredApprovals > 0 && _requiredApprovals <= _owners.length,
            "Invalid required approvals"
        );

        for (uint256 i; i < _owners.length; ++i) {
            address addr = _owners[i];
            require(addr != address(0), "invalid owner address");
            require(!isOwner[addr], "owners must be unique");

            owners.push(addr);
            isOwner[addr] = true;
        }

        requiredApprovals = _requiredApprovals;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint256 _value, bytes calldata _data) external onlyOwner {
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false
            })
        );

        emit Submit(msg.sender, transactions.length-1);
    }

    function approve(uint _txId) external 
        onlyOwner 
        txExists(_txId) 
        txNotApproved(_txId) 
        txNotExecuted(_txId) 
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint _txId) private view returns(uint count) {
        for(uint i; i<owners.length;++i) {
            address owner=owners[i];
            if(approved[_txId][owner]) {
                ++count;
            }
        }
    }

    function execute(uint _txId) external 
        txExists(_txId)
        txNotExecuted(_txId) 
    {
        require(_getApprovalCount(_txId) >= requiredApprovals, "Not enough approvals.");

        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;

        (bool ok,) = transaction.to.call{value:transaction.value}(transaction.data);
        require(ok, "transaction failed");

        emit Execute(_txId);
    }

    function revoke(uint _txId) external
        onlyOwner
        txExists(_txId)
        txNotExecuted(_txId) 
    {
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}
