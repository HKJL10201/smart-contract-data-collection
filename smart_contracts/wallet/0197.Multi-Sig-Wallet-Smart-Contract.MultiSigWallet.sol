//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract MulSigWall{
    
    event Deposited(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint txId);
    event Revoke(address indexed owner, uint txId);
    event Execute(uint indexed txId);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;

    constructor(address[] memory _owners, uint _required){
        require(_owners.length > 1, "Owners not found!");
        require(_required > 0 && _required <= owners.length
        ,"Invalid Number of Owners");
    
        for(uint i = 0 ; i < _owners.length ; i++){
            address owner = _owners[i];
            require(owner != address(0), "Invalid Owner");
            require(!isOwner[owner], "Owner is not Unique");
            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    receive() external payable{
        emit Deposited(msg.sender, msg.value);
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not Owner");
        _;
    }

    modifier txExists( uint _txId) {
        require(_txId > transactions.length, "TX does not exist");
        _;
    }

    modifier notApproved(uint _txId) {
        require(approved[_txId][msg.sender], "TX already approved");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "Already Executed");
        _;
    }

    function Submitted(address _to, uint256 _value, bytes calldata _data) 
    external onlyOwner {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        
        emit Submit(transactions.length - 1);
    }

    function approve(uint _txId) 
    external onlyOwner 
    txExists(_txId) notApproved(_txId) 
    notExecuted(_txId) {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function getApprovalCount(uint _txId) private view returns(uint count){
        for(uint i = 0; i < owners.length; i++){
            if(approved[_txId][owners[i]]){
                count += 1;
            }
        }
        return count;
    }

    function execute(uint _txId) external txExists(_txId) notApproved(_txId){
        require(getApprovalCount(_txId) >= required, "Approvals is less than required");
        Transaction storage transaction = transactions[_txId];

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value : transaction.value}(
            transaction.data
        );

        require(success, "TX failed!");

        emit Execute(_txId);
    }

    function revoke(uint _txId) external onlyOwner notApproved(_txId) txExists(_txId) {
        require(approved[_txId][msg.sender], "TX not approved!");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}