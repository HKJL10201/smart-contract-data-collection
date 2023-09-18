// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MultiSigWallet {

    event Deposit(address indexed sender, uint amount);
    event Approve(address indexed owner, uint txId);
    event Submit(uint indexed txId);
    event Revoke(address indexed owner, uint txId);
    event Execute(uint indexed txId);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public requireSignatures;

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not One Of The Owner");
        _;
    }

    modifier txExists(uint txId) {
        require(txId < transactions.length, "Trasactions Does not Exist");
        _;
    }

    modifier notApproved(uint txId) {
        require(!approved[txId][msg.sender], "Transaction Already Approved");
        _;
    }

    modifier notExecuted(uint txId) {
        require(!transactions[txId].executed, "Tx Already Executed");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "Owners Required ");
        require(_required > 0 && _required <= _owners.length, "Invalid Number Of Required Signatures");
        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid Address In List Of Owners");
            require(!isOwner[owner], "Owner is Not Unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        requireSignatures = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }


    function submitTransaction(address _to, uint _value, bytes calldata _data) external onlyOwner {
        transactions.push(Transaction({to: _to, value: _value, data: _data, executed: false}));
        emit Submit(transactions.length - 1);
    }

    function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId) {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint _txId) private view returns (uint count) {
        for (uint i; i < owners.length; i++) {
            if(approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    function executeTx(uint _txId) external txExists(_txId) notExecuted(_txId) {
        require(_getApprovalCount(_txId) >= requireSignatures, 'Not Enough Signatures');
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        
        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);

        require(success, 'Transaction did Not Go Trough');
        emit Execute(_txId);
    }

    function revokeTx(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(approved[_txId][msg.sender], "Tx Not Approved");

        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

    function getApporoved(address _user) public view returns (bool) {
        return isOwner[_user];
    }

    function getOwners() public view returns(address[] memory) {
        return owners;
    }

    function getTransaction(uint _idx) public view returns(Transaction memory) {
        require(_idx < transactions.length, "Out Of Bounds");
        return transactions[_idx];
    }

    function approvedTransactions(uint _txId) public view returns (bool) {
        return approved[_txId][msg.sender];
    }

    function executedTransactions(uint _txId) public view returns (bool) {
        return transactions[_txId].executed;
    }

    function getOwnersCount() public view returns (uint) {
        return owners.length;  
    }

    function getApprovalCount(uint _txId) public view returns (uint count) {
        for (uint i; i < owners.length; i++) {
            if(approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

}