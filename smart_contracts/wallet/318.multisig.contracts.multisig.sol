pragma solidity ^0.4.8;

/// @title 2 of 3 Multisig Wallet for use with Strato
contract multisig {

//addresses parameters for three signators
    address private _owner;
    address private _owner2;
    address private _owner3;

//properties
    uint private _transactionIdx;

    //minimum of 2 signatures (this is modifiable)
    uint constant minimum_sigs = 2;

    modifier isOwner() {
        require (msg.sender == _owner);
        _;
    }

    modifier approvedSigner() {
        require (msg.sender == _owner || msg.sender == _owner2 || msg.sender == _owner3);
        _;
    }

//constructor
    struct Transaction {
        address from;
        address to;
        uint amount;
        //how many people have signed?
        uint8 signatureCount;
        //who has signed?
        mapping(address => uint8) signatures;
    }

 //events
    event DepositFunds(address from, uint amount);
    event TransactionCreated(address from, address to, uint amount, uint transactionId);
    event TransactionCompleted(address from, address to, uint amount, uint transactionId);
    event TransactionSigned(address by, uint transactionId);
    
//mappings
    mapping (uint => Transaction) private _transactions;
    uint[] private _pendingTransactions;

//functions
    function InitMultisigWallet()
        public {
        _owner = msg.sender;
    }

    //add additional signees
    function addOwner2(address owner2) isOwner internal {
        _owner2 = owner2;
    }

    function addOwner3(address owner3) isOwner internal {
        _owner3 = owner3;
    }

//deposit funds to multisig contract and log as an event
    function depositToWallet() public {
        DepositFunds(msg.sender, msg.value);
    }

//transfer funds from multisig contract to another address
    function transferTo(address to, uint amount) approvedSigner public {
        //check to ensure not overspending
        require(address(this).balance >= amount);
        uint transactionId = _transactionIdx++;

        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.to = to;
        transaction.amount = amount;
        transaction.signatureCount = 0;
        //define where transaction exists in data structure
        _transactions[transactionId] = transaction;
        _pendingTransactions.push(transactionId);
        //emit event for frontend
        TransactionCreated(msg.sender, to, amount, transactionId);
    }

    function signTransaction(uint transactionId) approvedSigner public {
        Transaction storage transaction = _transactions[transactionId];
         //Make sure that the transaction exists
        require(0x0 != transaction.from);
         //The initiator does not count as a signee 
        require(msg.sender != transaction.from);
          // Cannot sign a transaction more than once
        require(transaction.signatures[msg.sender] != 1);
        transaction.signatures[msg.sender] = 1;
        transaction.signatureCount++;
        //emit the details of who signed it
        TransactionSigned(msg.sender, transactionId);

        if (transaction.signatureCount >= minimum_sigs) {
            require(address(this).balance >= transaction.amount);
            transaction.to.transfer(transaction.amount);
            TransactionCompleted(transaction.from, transaction.to, transaction.amount, transactionId);
      }
    }

    function walletBalance() public returns (uint) {
        return address(this).balance;
    }

}
