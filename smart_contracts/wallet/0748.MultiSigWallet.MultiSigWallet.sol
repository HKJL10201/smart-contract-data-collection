pragma solidity >=0.4.22 <0.9.0;

contract MultiSigWallet {
    
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner, 
        uint indexed txIndex, 
        address indexed to, 
        uint value, 
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    
    address[] public owners;
    uint public numConfirmationsRequired;
    
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        mapping(address => bool) isConfirmed;
        uint numConfirmations;
    }
    
    Transaction[] public transactions;
    
    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "Owners required");
        require(
            _numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length,
            "Invalid number of required confirmations"
        );
        
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner(owner), "Owner not unique");
            owners.push(owner);
        }
        
        numConfirmationsRequired = _numConfirmationsRequired;
    }
    
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    
    function submitTransaction(address _to, uint _value, bytes memory _data) public returns (uint) {
        require(isOwner(msg.sender), "Not an owner");
        uint txIndex = transactions.length;
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0
        }));
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
        return txIndex;
    }
    
    function confirmTransaction(uint _txIndex) public {
        require(isOwner(msg.sender), "Not an owner");
        Transaction storage transaction = transactions[_txIndex];
        require(!transaction.executed, "Transaction already executed");
        require(!transaction.isConfirmed[msg.sender], "Confirmation already submitted");
        transaction.isConfirmed[msg.sender] = true;
        transaction.numConfirmations += 1;
        emit ConfirmTransaction(msg.sender, _txIndex);
    }
    
    function revokeConfirmation(uint _txIndex) public {
        require(isOwner(msg.sender), "Not an owner");
        Transaction storage transaction = transactions[_txIndex];
        require(!transaction.executed, "Transaction already executed");
        require(transaction.isConfirmed[msg.sender], "Confirmation not found");
        transaction.isConfirmed[msg.sender] = false;
        transaction.numConfirmations -= 1;
        emit RevokeConfirmation(msg.sender, _txIndex);
    }
    
   function executeTransaction(uint _txIndex) public {
    require(isOwner(msg.sender), "Not an owner");
    Transaction storage transaction = transactions[_txIndex];
    require(!transaction.executed, "Transaction already executed");
    require(transaction.numConfirmations >= numConfirmationsRequired, "Not enough confirmations");
    transaction.executed = true;
    (bool success, ) = transaction.to.call{value: transaction.value}(
        transaction.data
    );
    require(success, "Transaction failed");
    emit ExecuteTransaction(msg.sender, _txIndex);
}

function isOwner(address _owner) public view returns (bool) {
    for (uint i = 0; i < owners.length; i++) {
        if (owners[i] == _owner) {
            return true;
        }
    }
    return false;
}

function getTransactionCount() public view returns (uint) {
    return transactions.length;
}

function getTransaction(uint _txIndex) public view returns (
    address to,
    uint value,
    bytes memory data,
    bool executed,
    uint numConfirmations
) {
    Transaction storage transaction = transactions[_txIndex];
    return (
        transaction.to,
        transaction.value,
        transaction.data,
        transaction.executed,
        transaction.numConfirmations
    );
}

function getConfirmations(uint _txIndex) public view returns (address[] memory) {
    Transaction storage transaction = transactions[_txIndex];
    address[] memory confirmations = new address[](owners.length);
    uint count = 0;
    for (uint i = 0; i < owners.length; i++) {
        if (transaction.isConfirmed[owners[i]]) {
            confirmations[count] = owners[i];
            count += 1;
        }
    }
    return confirmations;
}

function getOwners() public view returns (address[] memory) {
    return owners;
}

