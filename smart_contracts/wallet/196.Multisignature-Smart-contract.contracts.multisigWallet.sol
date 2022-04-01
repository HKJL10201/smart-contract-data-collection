pragma solidity ^0.5.0;

contract MultiSigWallet {

    address private _owner;
    mapping(address => uint8) private _owners;

    uint constant MIN_SIGN = 2;
    uint private _transactionIdx;

    struct Transaction {
        address from;
        address to;
        uint amount;
        uint8 signatureCount;
        mapping (address => uint8) signatures;
    }

    mapping (uint => Transaction) private _transactions;
    uint[] private _pendingTransactions;

    modifier isOwner(){
        require(msg.sender == _owner);
        _;
    }

    modifier validOwner(){
        require(msg.sender == _owner || _owners[msg.sender] == 1);
        _;
    }

    event DepositFunds(address from, uint amount);
    event TransactionCreated(address from, address to, uint amount, uint transactionId);
    event TransactionCompleted(address from, address to, uint amount, uint transactionId);
    event TransactionSigned(address by, uint transactionId);

    function MultiSigWallet() public {
        _owner = msg.sender;
    }

    //add owner
    function addOwner(address owner) isOwner public {
        _owners[owner] = 1;
    }

    //remove owner
    function removeOwner(address owner) isOwner public {
        _owners[owner] = 0;
    }

    // full back function
    function () public payable {
        DepositFunds(msg.sender, msg.value);
    }

    function withdraw(uint amount) validOwner public {
        transferTo(msg.sender, amount);
    }

    // transfer to address
    function transferTo(address to, uint amount) validOwner public {
        require(address(this).balance >= amount);
        //increase transaction id
        uint transactionId = _transactionIdx++;

        //init transaction struct
        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.to = to;
        transaction.amount = amount;
        transaction.signatureCount = 0;

        //mapping of transaction
        _transactions[transactionId] = transaction;
        _pendingTransactions.push(transactionId);

        //emit created transaction
        TransactionCreated(msg.sender, to, amount, transactionId);

    }

    function getPendingTransactions() view validOwner public returns(uint[]) {
        return _pendingTransactions;
    }

    function signTransaction(uint transactionId) validOwner public {
        Transaction storage transaction = _transactions[transactionId];

        //Transaction must exist
        require(0x0 != transaction.from);
        //Creator cannot sign the transaction
        require(msg.sender != transaction.from);
        //Cannot sign a transaction more than once
        require(transaction.signatures[msg.sender] != 1);

        transaction.signatures[msg.sender] = 1;

        transaction.signatureCount++;

        TransactionSigned(msg.sender, transactionId);

        if (transaction.signatureCount >= MIN_SIGN){
            //check if balance is enough
            require(address(this).balance >= transaction.amount);
            transaction.to.transfer(transaction.amount);
            TransactionCompleted(transaction.from, transaction.to, transaction.amount, transactionId);
            deleteTransaction(transactionId);
        }

    }

    function deleteTransaction(uint transactionId) validOwner public {
        uint8 replace = 0;

        require(_pendingTransactions.length > 0);

        for (uint i = 0; i < _pendingTransactions.length; ++) {
            if(1 == replace){
                _pendingTransactions[i-1] = _pendingTransactions[i];
            } else if (transactionId == _pendingTransactions[i]) {
                replace = 1;
            }
        }
        assert(replace == 1);
        delete _pendingTransactions[_pendingTransactions.length - 1];
        _pendingTransactions.length--;
        delete _transactions[transactionId];

    }

    function walletBalance() constant public returns (uint) {
        return address(this).balance;
    }


}