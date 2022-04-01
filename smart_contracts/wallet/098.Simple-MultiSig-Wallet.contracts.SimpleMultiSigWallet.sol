pragma solidity ^0.5.0;

/** @title MultiSignature Wallet. */

contract SimpleMultiSigWallet {

    /** @dev Multisignature wallet with transactions.      */

    address private _owner;
    mapping(address => uint8) private _owners;

    uint _transactionIdx;
    uint[] private _pendingTransactions;

    struct Transaction {
      address payable from;  
      address payable to;
      uint amount;
      uint8 ConfirmationCount;
      mapping (address => uint8) signatures; 
    }
    
    
    mapping(uint => Transaction) _transactions; /** creates unique transactionId for each struct Transaction */
    uint8 constant private _sigRequiredCount = 2; /** Minimum number of required signatures to execute transaction */
    
    /** Modifier for checking validity of owner of wallet */
    modifier validOwner() {
        require(msg.sender == _owner || _owners[msg.sender] == 1);
        //require(_owners[msg.sender] == 1);
        _;
    }

    //  Events
    event DepositEther(address from, uint amount);
    event TransactionCreated(address from, address to, uint amount, uint transactionId);
    event TransactionDone(address from, address to, uint amount, uint transactionId);
    event TransactionApprove(address by, uint transactionId);

    //Constructor - To initialize owner of contract
    constructor()
        public {
        // Set master contract owner
        _owner = msg.sender;
        
    }

    ///@dev Addition of owner to wallet
    function addOwner(address owner)
        // isOwner
        validOwner
        public {
        _owners[owner] = 1;
    }

    ///@dev Removal of owner from wallet
    function removeOwner(address owner)
        validOwner
        public {
        _owners[owner] = 0;
    }

    ///@dev Fallback function to add ether to wallet
    function ()
        external
        payable {
        emit DepositEther(msg.sender, msg.value);
    }

    function send()
      public
      payable{}

     /// @dev Fallback function allows to deposit ether.
    /// @dev Starts transaction for withdrawing money
    function withdraw(uint amount)
        validOwner
        public {
        transferTo(msg.sender, amount);
    }

    ///@dev Creation of transaction for withdrawal by creating transactionId
    ///@param to address to which amount is to be transferred
    ///@param amount amount to be transferred by transaction
    function transferTo(address payable to, uint amount)
        validOwner
        public {
        require(address(this).balance >= amount);
        uint transactionId = _transactionIdx++;
        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.to = to;
        transaction.amount = amount;
        transaction.ConfirmationCount = 0;
        _transactions[transactionId] = transaction;
        _pendingTransactions.push(transactionId);
        emit TransactionCreated(msg.sender, to, amount, transactionId);
    }

    ///@dev Gives currently ongoing transaction IDs
    function getActiveTransactions()
      validOwner
      view
      public
      returns (uint[] memory) {
      return _pendingTransactions;
    }

    ///@dev To sign the transaction by owner of wallet
    ///@param transactionId transactionId of transaction to be signed
    function confirmTransaction(uint transactionId)
      validOwner
      public {

      Transaction storage transaction = _transactions[transactionId];

      // Transaction must exist
      require(address(0x0) != transaction.from);
      //Creator cannot sign this
      require(msg.sender != transaction.from);
      // Has not already signed this transaction
      require(transaction.signatures[msg.sender] == 0);

      transaction.signatures[msg.sender] = 1;
      transaction.ConfirmationCount++;

      emit TransactionApprove(msg.sender, transactionId);

      if (transaction.ConfirmationCount >= _sigRequiredCount) {
        require(address(this).balance >= transaction.amount);
        transaction.to.transfer(transaction.amount);
        emit TransactionDone(msg.sender, transaction.to, transaction.amount, transactionId);
        deleteTransaction(transactionId);
      }
    }
  
    ///@dev Deletion of existing transaction
    ///@param transactionId transactionId of transaction to be deleted
    function deleteTransaction(uint transactionId)
      validOwner
      public {
      uint8 replace = 0;
      require(_pendingTransactions.length > 0);
      for(uint i = 0; i < _pendingTransactions.length; i++) {
          if (1 == replace) {
              _pendingTransactions[i-1] = _pendingTransactions[i];
          } else if (_pendingTransactions[i] == transactionId) {
              replace = 1;
          }
      }
      assert(replace == 1);
      // Created an Overflow
      delete _pendingTransactions[_pendingTransactions.length - 1];
      _pendingTransactions.length--;
      delete _transactions[transactionId];
    }

    ///@dev Gives Number of Pending Transaction which are remained to be confirmed
    function getNumberofPending()
      public
      view
      returns (uint) {
      return _pendingTransactions.length;
    }

    ///@dev Returns current balance of wallet
    function walletBalance()
        view
        public returns (uint) {
        return address(this).balance;
    }
}
