// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract multiSigWallet {

    address[] private owners;
    uint public numberOfMinApprove;

    // txId => address => did she/he approve the Tx?
    mapping(uint => mapping(address => bool)) public approvalForTxFromAddress;
    mapping(address => bool) public isOwner;
    Transaction[] private transactionArray;

    event Deposit(
        address indexed sender,
        uint amount
    );

    event Submit(
        uint indexed txId
    );

    event Approve(
        address indexed owner, 
        uint indexed txId
    );

    event Revoke(
        address indexed owner,
        uint indexed txId
    );

    event Execute(
        uint indexed txId
    );

    struct Transaction{
        uint value;
        address to;
        bytes data;
        bool executed;
    }

    modifier onlyOwner(){
        require(isOwner[msg.sender], "Message sender is not an owner");
        _;
    }

    modifier txExist(uint _txId){
        require(_txId < transactionArray.length && _txId >= 0, "Tx doesn't exist");
        _;
    }

    modifier transactionNotSend(uint _txId){
        require(transactionArray[_txId].executed == false, "Transaction already went through");
        _;
    }

    constructor(address[] memory _owner, uint _numberOfMinApprove){
        require(_numberOfMinApprove > 0 && _numberOfMinApprove <= _owner.length, "NumberOfMinApprove must be <= number of owners and larger than 0");

        for(uint i = 0; i < _owner.length; i++){
            require(!isOwner[_owner[i]], "Address is already an owner");
            require(_owner[i] != address(0), "Address 0 cannot be an owner");
            isOwner[_owner[i]] = true;
            owners.push(_owner[i]);
        }  
        numberOfMinApprove = _numberOfMinApprove;
    }


    function createTxRequest(uint _value, address _to, bytes calldata _data)public onlyOwner{
        transactionArray.push(Transaction(
             _value,
            _to,
            _data,
            false
            )   
        );
        emit Submit(transactionArray.length - 1);
    }

    function approveTxRequest(uint _txId) external onlyOwner txExist(_txId) transactionNotSend(_txId){  
        require(!approvalForTxFromAddress[_txId][msg.sender], "You already approved this transaction");  
        
        approvalForTxFromAddress[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function revokeApprovalForTx(uint _txId) external onlyOwner transactionNotSend(_txId) txExist(_txId){
        require(approvalForTxFromAddress[_txId][msg.sender], "You haven't approved this transaction"); 

        approvalForTxFromAddress[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

    //transactionNotSend secures against Re-entrancy
    function callTransaction(uint _txId) external onlyOwner txExist(_txId) transactionNotSend(_txId) returns(bool success){
        uint count;
        for(uint i = 0; i < owners.length; i++){
            if(approvalForTxFromAddress[_txId][owners[i]]){
                count += 1;
            }
        }
        require(count >= numberOfMinApprove, "Not enough owners approved the transaction");

        //to save some gas (because we don't have to reaccess the state variable(also indexing inside an array) outside the function multiple times
        Transaction storage transaction = transactionArray[_txId];

        transaction.executed = true;

        (success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction failed");
        emit Execute(_txId);
    }

    receive() payable external {
        emit Deposit(msg.sender, msg.value);
    }
}
