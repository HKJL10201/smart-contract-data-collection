//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract MultiSigWallet {

    event Deposit(address indexed sender,uint amount,uint balance);
    event SubmitTransaction(address indexed owner,uint indexed txIndex,address indexed to,uint value,bytes data);
    event ConfirmTransaction(address indexed owner,uint indexed txIndex);
    event RevokeTransaction(address indexed owner,uint indexed txIndex);
    event ExecuteTransaction(address indexed owner,uint indexed txIndex);

    // The indexed parameters for logged events will allow you to search for these events using the indexed parameters as filters.

    address [] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;
    mapping(uint => mapping(address => bool)) public isConfirmed; //Mapping from txIndex->owner->bool

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    Transaction [] public transactions;

    constructor(address [] memory _owners,uint _numConfirmationsRequired)  {

        require(_owners.length > 0, "Owners Required");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length,
                "invalid number of required confirmations");

        for (uint i = 0; i < _owners.length; i++){
            address owner = _owners[i];
            require(owner != address(0),"invalid owner");
            require(!isOwner[owner],"Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        numConfirmationsRequired = _numConfirmationsRequired;

    }


    modifier onlyOwner(){
        require(isOwner[msg.sender], "not Owner");
        _;
    }

    modifier txExists(uint _txIndex){
        require(_txIndex < transactions.length,"transaction does not exist");
        _;
    }
    modifier notExecuted(uint _txIndex){
        require(!transactions[_txIndex].executed, "Transaction already Executed");
        _;
    }
    modifier notConfirmed(uint _txIndex){
        require(!isConfirmed[_txIndex][msg.sender],"Transaction has been confirmed");
        _;
    }

    fallback() external payable{
        emit Deposit(msg.sender,msg.value,address(this).balance);
    }

    receive() external payable {     
        emit Deposit(msg.sender,msg.value,address(this).balance);
    }

    function deposit() public payable{
    }

    function submitTransaction(address _to, uint _value,bytes memory _data) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0 }));
        emit SubmitTransaction(msg.sender,txIndex, _to, _value, _data);
        
    }
    function confrimTransaction(uint _txIndex)public onlyOwner txExists(_txIndex) notExecuted(_txIndex)  notConfirmed (_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        isConfirmed[_txIndex][msg.sender] = true;
        transaction.numConfirmations += 1;
        emit ConfirmTransaction(msg.sender, _txIndex);
    }
    function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.numConfirmations >= numConfirmationsRequired,"Cannot Execute Transactions");
        transaction.executed = true;
        (bool success,)= transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "transaction Failed");
        emit ExecuteTransaction(msg.sender, _txIndex);
    }
    function revokeConfirmation(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex){
        Transaction storage transaction = transactions[_txIndex];
        require(isConfirmed[_txIndex][msg.sender],"Tx not confirmed");
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;
        emit RevokeTransaction(msg.sender, _txIndex);

    }
    function getOwners() public view returns(address [] memory){
        return owners;
    }
    function getTransactionCount() public view returns (uint){
        return transactions.length;
    } 
}

contract TestContract {

    uint public i;
    function callMe(uint j) public {
        i += j;
    }
    function getData() public pure returns (bytes memory){
        return abi.encodeWithSignature("callMe(uint256)",123);
    }
}

