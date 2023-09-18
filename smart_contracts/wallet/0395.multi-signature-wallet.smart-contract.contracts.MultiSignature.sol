// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract MultiSignature
{
    uint public numConformationsRequired;                                           // Number of confirmations required to execute a transaction
    address[] public owners;                                                        // Owners of the wallet

    struct Transaction
    {
        address from;                   // The sender address. The sender can not confirm his own transaction
        address to;                     // recipient's address
        uint value;                     // number of ether (wei) sent
        uint numConfirmations;          // number of pending confirmation of the transaction
        bool executed;                  // state of the execution of the transaction
        bytes data;                     // data stored inside the transaction
    }

    mapping(address => bool) public isOwner;
    mapping(uint => mapping(address => bool)) public isTransactionConfirmed;

    Transaction[] public transactions;

    event Deposit(address indexed sender, uint amount, uint balance);
    event Submit(
        address indexed owner, 
        uint indexed trxIndex, 
        address indexed to, 
        uint value, 
        bytes data);
    event Confirm(address indexed owner, uint indexed trxIndex);
    event Cancel(address indexed owner, uint indexed trxIndex);
    event Execute(address indexed owner, uint indexed trxIndex);

    modifier onlyOwner()
    {
        require(isOwner[msg.sender], "The address is not an owner");
        _;
    }

    modifier trxExist(uint _index)
    {
        require(_index < transactions.length, "The transaction does not exit");
        _;
    }

    modifier pendingState(uint _index)
    {
        require(transactions[_index].executed == false, "The transaction has already been executed");
        _;
    }

    modifier notConfirmedByOwner(uint _index)
    {
        require(isTransactionConfirmed[_index][msg.sender] == false, "The transaction has already been confirmed");
        _;
    }

    modifier notInitiator(uint _index)
    {
        require(transactions[_index].from != msg.sender, "This transaction belgons to you. You can not perform a validation");
        _;
    }

    modifier alreadyConfirmed(uint _index)
    {
        require(isTransactionConfirmed[_index][msg.sender], "You have not confirmed that transaction");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired)
    {
        require(_owners.length > 0, "Owners required");
        require(
            _numConfirmationsRequired > 0 && 
            _numConfirmationsRequired <= _owners.length, 
            "Invalid number of required confirmations"
            );
        
        for(uint i = 0; i < _owners.length; i++)
        {
            address owner = _owners[i];

            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner is not unique");
            isOwner[owner] = true;
            owners.push(owner);
        } 
        numConformationsRequired = _numConfirmationsRequired;
    }

    receive() payable external
    {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function deposit() payable external
    {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner
    {
        uint txIndex = transactions.length;
        transactions.push(Transaction({
            to: _to,
            from: msg.sender,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations : 0
        }));
        emit Submit(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex) public onlyOwner trxExist(_txIndex) pendingState(_txIndex) notConfirmedByOwner(_txIndex) notInitiator(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        isTransactionConfirmed[_txIndex][msg.sender] = true;
        transaction.numConfirmations += 1;

        emit Confirm(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex) public onlyOwner trxExist(_txIndex) pendingState(_txIndex)
    {
         Transaction storage transaction = transactions[_txIndex];
         require(transaction.numConfirmations >= numConformationsRequired,
         "Cannot execute the transaction");

         transaction.executed = true;
         (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
         require(success, "Transaction has failed");

         emit Execute(msg.sender, _txIndex);
    }

    function cancelConfirmation(uint _txIndex) public onlyOwner trxExist(_txIndex) pendingState(_txIndex) alreadyConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        isTransactionConfirmed[_txIndex][msg.sender] = false;
        transaction.numConfirmations -= 1;

        emit Cancel(msg.sender, _txIndex);
    }

    function getOwner() public view returns (address[] memory)
    {
        return owners;
    }

    function getTransactionCount() public view returns (uint)
    {
        return transactions.length;
    }

    function getTransaction(uint _index) public view returns(address to, address from, uint value, bytes memory data, bool executed, uint numConfirmations)
    {
        Transaction storage transaction = transactions[_index];

        return (
            transaction.to,
            transaction.from,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}