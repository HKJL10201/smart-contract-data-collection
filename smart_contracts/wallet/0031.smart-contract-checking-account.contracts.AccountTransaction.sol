pragma solidity ^0.4.23;

import "./AccountAuthorizer.sol";


contract AccountTransaction is AccountAuthorizer {

    // the minimum signatures for authorize the transaction
    uint256 public constant MIN_SIGNATURES_ADVISER = 2;
    uint256 public constant MIN_SIGNATURES_COLAB = 4;

    uint256 internal _transactionIdx;

    //list the pending transations
    uint256[] internal _pendingTransactions;

    //status of transactions
    enum StatusTransaction {WAITING, CANCELLED, SENDED}
    StatusTransaction statusTransaction;    

    mapping (uint256 => Transaction) internal _transactions;

    event LogDebug(string msg);
    event TransactionCancelled(uint256 transactionId);
    event TransactionSendTokenCreated(address from, address to, uint256 amount, uint256 transactionId);
    event TransactionSendTokenCompleted(address from, address to, uint256 amount, uint256 transactionId);
    event TransactionSendTokenSigned(address by, uint256 transactionId);

    //A struct to hold the Transaction's information about 
    // the transfering of tokens from an address to another
    struct Transaction {
        address from;
        address to;
        bytes32 description;
        uint256 amount;
        uint256 date;
        uint8 signatureCountColab;
        uint8 signatureCountAdviser;
        StatusTransaction statusTransaction;    
        mapping (address => uint8) signaturesColabs;
        mapping (address => uint8) signaturesAdviser;
    }
  
    // get the list off transactions  
    function getPendingTransactions() public view returns(uint256[]){
        return _pendingTransactions;
    }
  

    //Get the transation to send tokens
    function getTransactionSendToken(uint256 _transactionId) public onlyAuthorizer view 
                                            returns (address from, address to, uint256 amount, 
                                            bytes32 description, uint256 date, uint8 signatureCountColab,
                                            uint8 signatureCountAdviser, StatusTransaction status) 
    {
        from = _transactions[_transactionId].from;
        to = _transactions[_transactionId].to;
        amount = _transactions[_transactionId].amount;
        description = _transactions[_transactionId].description;
        date = _transactions[_transactionId].date;
        signatureCountColab = _transactions[_transactionId].signatureCountColab;
        signatureCountAdviser = _transactions[_transactionId].signatureCountAdviser;
        status = _transactions[_transactionId].statusTransaction;
        return (from, to, amount, description, date, signatureCountColab, signatureCountAdviser, status);
    }

    //Sign a transaction to send tokens
    function signTransactionSendToken(uint256 _transactionId) public onlyAuthorizer {

        Transaction storage transaction = _transactions[_transactionId];
        // Transaction must exist
        require(0x0 != transaction.from);
        // Creator cannot sign the transaction
        require(msg.sender != transaction.from);
        // check the states os transaction
        assert(transaction.statusTransaction == StatusTransaction.WAITING);

        if (_authorizers[msg.sender].typeAuthorizer == TypeAuthorizer.COLAB) {
            // Cannot sign a transaction more than once
            assert(transaction.signaturesColabs[msg.sender] == 0);
            transaction.signaturesColabs[msg.sender] = 1;
            transaction.signatureCountColab++;
        } else {
            // Cannot sign a transaction more than once
            assert(transaction.signaturesAdviser[msg.sender] == 0);
            
            transaction.signaturesAdviser[msg.sender] = 1;
            transaction.signatureCountAdviser++;            
        }

        emit TransactionSendTokenSigned(msg.sender, _transactionId);

        if (transaction.signatureCountColab >= MIN_SIGNATURES_COLAB || transaction.signatureCountAdviser >= MIN_SIGNATURES_ADVISER ) {
            require(address(this).balance >= transaction.amount);
            emit TransactionSendTokenCompleted(transaction.from, transaction.to, transaction.amount, _transactionId);
            transaction.to.transfer(transaction.amount);
            updateStatusTransactionSendToken(_transactionId, StatusTransaction.SENDED);
        }
    }

    //Delete a transaction to send tokens
    function updateStatusTransactionSendToken(uint256 _transactionId, StatusTransaction _statusTransaction) internal {
        _transactions[_transactionId].statusTransaction = _statusTransaction;
    }

    //delete a transaction pending by owner of contract
    function deleteTransactionSendToken(uint256 _transactionId) external onlyOwner {
        require(_transactions[_transactionId].statusTransaction == StatusTransaction.WAITING);
        _transactions[_transactionId].statusTransaction = StatusTransaction.CANCELLED;
        emit TransactionCancelled(_transactionId);
    } 
}