// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract MultiSigWallet {
    event Deposited(uint amount, address indexed sender);
    event SubmitTransaction(uint txId);
    event ApproveTransaction(uint txId, address indexed owner);
    event RevokeTransaction(uint txId, address indexed owner);
    event DoTransaction(uint txId);

    address[] owners;
    mapping(address => bool) private isOwner;
    uint private minSigners;
    uint lockedTime;

    struct Transaction {
        address to;
        uint amount;
        bool completed;
        uint noSigners;
    }

    Transaction[] public transctions;
    //mapping(uint => mapping(address => bool)) public txConfirmation;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Owner doesnt exsist");
        _;
    }

    modifier txIdExsist(uint _txId) {
        require(_txId < transctions.length, "Transaction doesn't exsist");
        _;
    }
    
    modifier notCompleted(uint _txId) {
        require(!transctions[_txId].completed, "Transaction already completed");
        _;
    }

    modifier isLocked {
        require(block.timestamp > lockedTime, "Please wait 24 hrs before adding new transaction");
        _;
    }

    constructor(address[] memory _owners, uint _minSigners) {
        if (_minSigners == 0) {
            minSigners = _owners.length;
        } else {
            require(_minSigners <= _owners.length, "Invalid minimum signers");
            minSigners = _minSigners;
        }
        for(uint i=0; i<_owners.length; i++) {
            require(_owners[i] != address(0), "Owner address invalid!");
            require(!isOwner[_owners[i]], "Owner is already present!");
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }
    }

    receive() external payable {
        emit Deposited(msg.value, msg.sender);
    }

    function addTransaction(address _to, uint _amount) public onlyOwner isLocked {
        require(_to != address(0), "Address Null!");
        require(_amount > 0, "Ether amount is Null");
        emit SubmitTransaction(transctions.length);
        transctions.push(Transaction(_to, _amount, false, 0));
        lockedTime = block.timestamp + 24 hours;
    }

    function approveTransaction(uint _txId) public onlyOwner txIdExsist(_txId) notCompleted(_txId) {
        transctions[_txId].noSigners += 1;
        emit ApproveTransaction(_txId, msg.sender);
    }

    function revokeTransaction(uint _txId) public onlyOwner txIdExsist(_txId) notCompleted(_txId) {
        transctions[_txId].noSigners -= 1;
        emit RevokeTransaction(_txId, msg.sender);
    }

    function executeTransaction(uint _txId) public txIdExsist(_txId) notCompleted(_txId) {
        require(transctions[_txId].noSigners >= minSigners, "Tansaction not approved from min signers");
        require(transctions[_txId].amount < address(this).balance, "Not enough funds!");

        (bool sent, ) = transctions[_txId].to.call{value: transctions[_txId].amount}("");
        require(sent, "Failed to send Ether");
        transctions[_txId].completed = true;
        emit DoTransaction(_txId);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transctions.length;
    }
    
}
