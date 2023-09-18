// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.9 < 0.9.0;
contract MultiSig{
    address[] public owners;
    uint public numOfConfirmationRequired;

    struct Transaction{
        address to;
        uint value;
        bool isExecuted;
    }

    mapping(uint => mapping(address => bool)) public isConfirmed;
    Transaction[] public transactions;
    event TransactionSubmitted(uint transactionId , address receiver , address sender , uint value);
    event TransactionConfirmed(uint transactionId);
    event TransactionExecuted(uint transactionId);

    constructor(address[] memory _owners , uint _numOfConfirmationRequired){
        require(_owners.length > 1 , "Owners must be greater than 1");
        require(_numOfConfirmationRequired > 0 && _numOfConfirmationRequired <= _owners.length, "Invalid number for confirmation required");
        for(uint i = 0 ; i<_owners.length ; i++){
            require(_owners[i]!=address(0) , "Invalid address of the owner");
            owners.push(_owners[i]);
        }
        numOfConfirmationRequired = _numOfConfirmationRequired;
    }

    function submitTransaction(address _to , uint _value) public payable{
        require(_to != address(0) , "Invalid address for recipient");
        require(msg.value > 0 , "Enter valid amount");
        uint transactionId = transactions.length;
        transactions.push(Transaction({to:_to ,value: _value , isExecuted:false}));
        emit TransactionSubmitted( transactionId ,   msg.sender , _to , msg.value);
    }

    function cofirmTransaction(uint _transactionId) public {
        require( _transactionId < transactions.length , "Invalid transaction Id");
        require( !isConfirmed[_transactionId][msg.sender] , "Transaction already completed");
        isConfirmed[_transactionId][msg.sender] = true;
        emit TransactionConfirmed(_transactionId);
        if(isTransactionConfirmedByOwners(_transactionId)){
            executeTransaction(_transactionId);
        }
    }

    function isTransactionConfirmedByOwners(uint _transactionId) internal view returns(bool){
        require( _transactionId < transactions.length , "Invalid transaction Id");
        uint confirmationCount;
        for(uint i = 0 ; i < owners.length ; i++){
            if(isConfirmed[_transactionId][owners[i]] )
                confirmationCount++;
        }
        return confirmationCount>=numOfConfirmationRequired;
    }
    
    function executeTransaction(uint _transactionId) public payable {
        require( _transactionId < transactions.length , "Invalid transaction Id");
        require(!transactions[_transactionId].isExecuted , "Transaction is already completed");
        (bool success,) =transactions[_transactionId].to.call{value: transactions[_transactionId].value}("");
        require(success , "Transaction failed");
        transactions[_transactionId].isExecuted = true;
        emit TransactionExecuted(_transactionId);

    }
}
