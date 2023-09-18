// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultisigWallet{
    event Deposit(address indexed sender,uint amount,uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txnIndex,
        address indexed to,
        uint value,
       bytes data
    );
    event ConfirmTransaction(address indexed owner,uint indexed txnIndex);
    event RevokedTransaction(address indexed owner,uint indexed txnIndex);
    event ExecuteTransaction(address indexed owner,uint indexed txnIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction{
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    mapping(uint => mapping(address=>bool)) public  isConfirmed;
    Transaction[] public transactions;

    modifier onlyOwner(){
        require(isOwner[msg.sender],"Execution failed: Only Owner can execute");
        _;
    }

    modifier txnExists(uint _txnIndex){
        require(_txnIndex < transactions.length,"Transaction does not exist");
        _;
    }

    modifier notExecuted(uint _txnIndex){
        require(!transactions[_txnIndex].executed,"Transaction already executed");
        _;
    }

    modifier notConfirmed(uint _txnIndex){
        require(!isConfirmed[_txnIndex][msg.sender],"Transaction already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired)
    {
        require(_owners.length > 0,"Atleast one owner Required");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length,"Invalid Number of confirmations");
        for(uint i=0; i<_owners.length;i++)
        {
            address owner = _owners[i];
            require(owner != address(0),"Invalid Owner");
            require(!isOwner[owner],"Owner not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    

    function confirmTransaction(uint _txnIndex) public onlyOwner notConfirmed(_txnIndex) notExecuted(_txnIndex) txnExists(_txnIndex){
        Transaction storage transaction = transactions[_txnIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txnIndex][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, _txnIndex);
    }

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    )public onlyOwner{
        uint txnIndex = transactions.length;
        transactions.push(
            Transaction({
                to : _to,
                value : _value,
                data : _data,
                executed : false,
                numConfirmations : 0
            })
        );
        emit SubmitTransaction(msg.sender, txnIndex, _to, _value, _data);
    }

  

    function depositETH() public payable{
        (bool success,) = address(this).call{value:msg.value}("");
        require(success,"Invalid");
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    receive() external payable{}


    function executeTransaction(uint _txnIndex) public onlyOwner notExecuted(_txnIndex) txnExists(_txnIndex){
        Transaction storage transaction = transactions[_txnIndex];
        require(transaction.numConfirmations>= numConfirmationsRequired,"Cannot execute transaction");
        transaction.executed = true;
        (bool success,) = transaction.to.call{gas:20000,value:transaction.value}(transaction.data);
        require(success,"Transaction failed");
        emit ExecuteTransaction(msg.sender, _txnIndex);
    }

    function revokeTransaction(uint _txnIndex) public onlyOwner txnExists(_txnIndex) notExecuted(_txnIndex)
    {
        Transaction storage transaction = transactions[_txnIndex];
        require(isConfirmed[_txnIndex][msg.sender],"Transaction is not Confirmed");
        transaction.numConfirmations -= 1;
        isConfirmed[_txnIndex][msg.sender] = false;      
        emit RevokedTransaction(msg.sender, _txnIndex);
    }

    function getOwners() public view returns(address[] memory) 
    {
        return owners;
    }

    function getTransactionCount() public view returns(uint)
    {
        return transactions.length;
    }

    function getTransaction(uint _txnIndex) public view returns(
        address to,
        uint value,
        bytes memory data,
        bool executed,
        uint numConfirmations
    ){
        Transaction storage transaction = transactions[_txnIndex];
        return(
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations

        );
    }

}