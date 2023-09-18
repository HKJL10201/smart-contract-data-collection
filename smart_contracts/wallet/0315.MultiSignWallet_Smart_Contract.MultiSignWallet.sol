// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./IMSW.sol";


contract MultiSignWallet is IMSW {

    address[] private _owners;
    uint private _required;

    struct Transaction {
        address to;
        uint value;
        bool executed;
    }

    Transaction[] private _transactions;

    mapping(address => bool) private _onlyOwner;
    mapping(uint => mapping(address => bool)) private _approved;
    mapping(address => uint) private _amountGiven;

    modifier isOwner(){
        require(msg.sender != address(0) , "invalid address");
        require(_onlyOwner[msg.sender] , "not owner");
        _;
    }

    modifier txExist(uint txId){
        require(txId < _transactions.length , "txId > tx.length" );
        _;
    }

    modifier notApproved(uint txId){
        require(!_approved[txId][msg.sender] , "already approved");
        _;
    }

    modifier approved(uint txId){
        require(_approved[txId][msg.sender] , "not approved");
        _;
    }

     modifier notExecuted(uint txId){
        Transaction memory transaction = _transactions[txId];
        require(!transaction.executed , "already executed");
        _;
    }

    constructor(address[] memory owners_ , uint required_ ){
        for(uint i = 0 ; i < owners_.length ; i++){
            address owner = owners_[i];
            _onlyOwner[owner] = true;
            _owners.push(owner);
        }
        _required = required_;
    }

    function submit(address to , uint value) external isOwner {
        _transactions.push(Transaction({
            to : to,
            value : value,
            executed : false
        }));
    }

    function approve(uint txId) external isOwner txExist(txId) notApproved(txId) notExecuted(txId){
        _approved[txId][msg.sender] = true;
    }

    function unapprove(uint txId ) external isOwner txExist(txId) approved(txId) notExecuted(txId) {
        _approved[txId][msg.sender] = false;
    }

    function getApprovalCount(uint txId) public view returns(uint count) {

        for(uint i = 0 ; i < _owners.length ; i++){
            if(_approved[txId][_owners[i]] == true){
                count += 1;
            }
        }

    }

    function execute(uint txId , uint _amount ) external txExist(txId) notExecuted(txId) {
        Transaction storage transaction = _transactions[txId];
        uint approvalCount = getApprovalCount(txId);
        require(approvalCount >= _required , "approvalCount < required");
        transaction.executed = true;
        _amountGiven[transaction.to] += _amount;
    }

    function getAmounts(address to) public view returns(uint){
        return _amountGiven[to];
    }

}