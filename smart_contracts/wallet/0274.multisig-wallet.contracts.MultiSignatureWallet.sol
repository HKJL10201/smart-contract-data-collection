// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract MultiSignatureWallet {

    struct Transaction {
      bool executed;
      address destination;
      uint value;
      bytes data;
    }
    
    // array of all the owner addresses 
    address[] public owners;
    
    // mapping to see quickly if address is an owner
    mapping (address => bool) public isOwner;
    
    // variable to keep track of number of addresses needed to verify trasnaction 
    uint public required;
    
    //count of trasnactions 
    uint public transactionCount;
    
    // trasnactions mapping
    mapping (uint => Transaction) public transactions;

    mapping (uint => mapping (address => bool)) public confirmations;
    
    event Deposit(address indexed sender, uint value);
    
    event Submission(uint indexed transactionId);
    
    event Confirmation(address indexed sender, uint indexed transactionId);
    
    event RevokeConfirmation(address indexed sender, uint indexed transactionId);
    
    event Execution(uint indexed transactionId);

    event ExecutionFailure(uint indexed transactionId);

    modifier validRequirement(uint ownerCount, uint _required) {
      if (_required > ownerCount || _required == 0 || ownerCount == 0) {
        revert();
      }
      _;
    }

    /// @dev Fallback function allows to deposit ether.
    fallback() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
	    }
    }
 
    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint _required) {
        for (uint i = 0; i < _owners.length; i++) {
          isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }
    
    function add(uint a, uint b) public returns (uint){ uint c = a + b; return c; }

    function submitTransaction(address destination, uint value, bytes memory data) public returns (uint transactionId) {
        require(isOwner[msg.sender]);
        uint trasnactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId) public {
        require(isOwner[msg.sender]);
        require(transactions[transactionId].destination != address(0));
        require(confirmations[transactionId][msg.sender] == false);
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId) public {
      require(isOwner[msg.sender]);
      require(transactions[transactionId].destination != address(0));
      require(confirmations[transactionId][msg.sender] == true);
      confirmations[transactionId][msg.sender] = false;
      emit RevokeConfirmation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId) public {
      require(transactions[transactionId].executed == false);
      if (isConfirmed(transactionId)) {
        Transaction storage t = transactions[transactionId];
        t.executed = true;
        (bool success, bytes memory returnedData) = t.destination.call{value : t.value}(t.data);
        if (success)
          emit Execution(transactionId);
        else {
          emit ExecutionFailure(transactionId);
          t.executed = false;
        }
      }
    }

    /*
     * (Possible) Helper Functions
     */
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId) internal view returns (bool) {
      uint count = 0;
      for (uint i = 0; i < owners.length; i++) {
        if (confirmations[transactionId][owners[i]]) {
          count += 1;
        }
        if (count == required) {
          return true;
        }
      }
    }

    function addTransaction(address destination, uint value, bytes memory data) internal returns (uint transactionId) {
      transactionId = transactionCount;
      transactions[transactionId] = Transaction({
        executed: false,
        destination: destination,
        value: value,
        data: data
      });
      emit Submission(transactionCount);
      transactionCount += 1;
    }
}