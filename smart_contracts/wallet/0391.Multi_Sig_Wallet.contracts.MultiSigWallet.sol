// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "OpenZeppelin/openzeppelin-contracts@4.7.3/contracts/utils/math/SafeMath.sol";

contract MultiSigWallet {

    using SafeMath for uint;

    uint public approvalThreshold;
    address[] public Owners;

    mapping(address => bool) public isOwner;
    mapping(uint => address) public txSubmittedBy;
    mapping(uint => mapping(address => bool)) public txApproval;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    Transaction[] public allTransactions;

    modifier onlyOwner {
        require(isOwner[msg.sender]);
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < allTransactions.length, "Enter valid transaction ID");
        _;
    }

    modifier txNotExecuted(uint _txId) {
        require(!allTransactions[_txId].executed);
        _;
    }

    event approvalThresholdUpdated(uint _newThreshold);
    event newOwnerAdded(address _newOwner);
    event receivedFunds(address _sender, uint _value);
    event newTxSubmitted(uint _txId);
    event txApproved(address _approver, uint _txId);
    event txExecuted(uint _txId);
    event approvalRevoked(address _revoker, uint _txId);

    constructor() {
        require(msg.sender != address(0) && !isOwner[msg.sender]);
        Owners.push(msg.sender);
        isOwner[msg.sender] = true;
    }

    receive() external payable{
        emit receivedFunds(msg.sender, msg.value);
    }


    function addOwner(address _owner) external onlyOwner returns (bool) {
        require(_owner != address(0) && !isOwner[_owner]);
        
        Owners.push(_owner);
        isOwner[_owner] = true;

        uint ownerCount = Owners.length;
        approvalThreshold = ownerCount.mul(90).div(100); 

        emit approvalThresholdUpdated(approvalThreshold);
        emit newOwnerAdded(_owner);
    }


    // we use calldata when parameters need to be accessed externally and it is cheaper than memory (Smart Contract Programmer)
    function submitTransaction(address _to, uint _value, bytes calldata _data) external onlyOwner {
        require(_to != address(0), "Enter valid address");

        // will worry about below while building the actual product - easy enough just add if statements
        //txSubmittedBy[allTransactions.length.sub(1)] = msg.sender;

        allTransactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));

        emit newTxSubmitted(allTransactions.length - 1);
    }


    function approveTransaction(uint _txId) 
        external 
        onlyOwner 
        txExists(_txId) 
        txNotExecuted(_txId) 
    {
        txApproval[_txId][msg.sender] = true;
        emit txApproved(msg.sender, _txId);
    }


    // putting variable names in function's returns saves gas  
    function _getApprovals(uint _txId) private view returns (uint count) {
        for(uint i=0; i < Owners.length; i++) {
            if(txApproval[_txId][Owners[i]]) {
                count += 1;
            }
        }
    }


    function executeTransaction(uint _txId) external onlyOwner txExists(_txId) txNotExecuted(_txId) {
        require(_getApprovals(_txId) >= approvalThreshold, "Need more approvals to execute");

        //allTransactions[_txId].executed = true;

        // using storage here as transactions array needs to be updated
        Transaction storage tran = allTransactions[_txId];
        tran.executed = true;

        (bool success, ) = tran.to.call{value: tran.value}(tran.data);

        require(success, "Transaction Failed");

        emit txExecuted(_txId);
    }


    function revokeApproval(uint _txId) external onlyOwner txExists(_txId) txNotExecuted(_txId) {
        txApproval[_txId][msg.sender] = false;
        emit approvalRevoked(msg.sender, _txId);
    }
}