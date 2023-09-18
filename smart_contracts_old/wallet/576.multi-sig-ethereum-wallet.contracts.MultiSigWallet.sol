pragma solidity ^0.5.11;

contract MultiSigWallet {

    // Events
    event Deposit(address indexed sender, uint amount, uint balalnce);
    event SubmitTransaction(address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data);
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeTransaction(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    // State variables
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numberOfConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        mapping(address => bool) isConfirmed;
        uint numberOfConfirmations;
    }

    Transaction[] public transactions;

    // Constructor
    constructor(address[] memory _owners, uint _numberOfConfirmationsRequired) public {

        require(_owners.length > 0, "Owners required");
        require(_numberOfConfirmationsRequired > 0 && _numberOfConfirmationsRequired <= _owners.length);

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "Invalid owner!");
            require(!isOwner[owner], "Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numberOfConfirmationsRequired = _numberOfConfirmationsRequired;
    }

    // Fallback function
    function() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // Modifiers
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "Transaction doesn't exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "Transaction already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!transactions[_txIndex].isConfirmed[msg.sender], "Transaction alreafy confirmed");
        _;
    }

    // Functions
    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {

        uint txIndex = transactions.length;

        transactions.push(Transaction({
        to: _to,
        value: _value,
        data: _data,
        executed: false,
        numberOfConfirmations: 0
        }));

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {

        Transaction storage transaction = transactions[_txIndex];

        transaction.isConfirmed[msg.sender] = true;
        transaction.numberOfConfirmations += 1;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {

        Transaction storage transaction = transactions[_txIndex];

        require(transaction.numberOfConfirmations >= numberOfConfirmationsRequired, "Not enough confirmation to execute transaction");

        transaction.executed = true;

        (bool success, ) = transaction.to.call.value(transaction.value)(transaction.data);
        require(success, "Transaction failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {

        Transaction storage transaction = transactions[_txIndex];

        transaction.isConfirmed[msg.sender] = false;
        transaction.numberOfConfirmations -= 1;

        emit RevokeTransaction(msg.sender, _txIndex);
    }

    // Helper function for Remix testing
    function deposit() payable external {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
}
