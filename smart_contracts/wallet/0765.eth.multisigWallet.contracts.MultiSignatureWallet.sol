pragma solidity ^0.5.0;

contract MultiSignatureWallet {
    
    struct Transaction {
      bool executed;
      address destination;
      uint value;
      bytes data;
    }

    // The following three variables are public, meaning they can be read and will be stored for the duration of the contract.
    address[] public owners; // Array of addresses where we will store owners.
    uint public required; // Unsigned integer about the sig count required to validate transaction.
    mapping (address => bool) public isOwner; // A mapper of address to boolean to represent ownership property.
    uint public transactionCount;
    mapping (uint => Transaction) public transactions;
    mapping(uint=> mapping (address=>bool)) public confirmations;

    event Deposit(address indexed sender, uint value);
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Submission(uint indexed transactionId);

    /// @dev Fallback function allows to deposit ether.
    function()
    	external
        payable
    {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
	}
    }

    // Modifier below is to 
    modifier validRequirement(uint ownerCount, uint _required){
        if ( _required > ownerCount || _required == 0 || ownerCount == 0)
            revert();
        _; // The function body is inserted inplace of the underscore.
    }

    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint _required) public 
    validRequirement(_owners.length, _required){
        for (uint i=0; i<_owners.length ;i++){
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.

    function submitTransaction(address destination, uint value, bytes memory data)
        public 
        returns (uint transactionId)
    {
        require(isOwner[msg.sender]);
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId) public {
        // Only wallet owners should be able to call this function
        // Verify that a transaction exists at a specified transactionId
        // We want to verify the msg.sender has not already confirmed the transaction
        require(isOwner[msg.sender]);
        require(transactions[transactionId].destination != address(0));
        require(confirmations[transactionId][msg.sender] == false);
        confirmations[transactionId][msg.sender] == true;
        // Since this function modifies confirmations which is part of the state, we should emit an event for best practices
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    /// function revokeConfirmation(uint transactionId) public {}

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId) public 
    {
        // Validate if requirements are met, if so, execute 
        // Requirements: transaction has not been executed before, m-of-n quorum
        require(transactions[transactionId].executed == false);
        if(isConfirmed(transactionId)){
            Transaction storage t = transactions[transactionId];// the storage keyword here makes "t" a pointer to storage
            t.executed = true;
            (bool success, bytes memory returnedData) = t.destination.call.value(t.value)(t.data);
            if (success)
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                t.executed = false; // not really needed
            }
        }
        }

		/*
		 * (Possible) Helper Functions
		 */
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId) public view returns (bool) 
        {
            uint count = 0;
            for(uint i=0; i<owners.length; i++){
                if (confirmations[transactionId][owners[i]])
                    count += 1;
                if (count == required)
                    return true;
            }
        }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes memory data) internal returns (uint transactionId) 
    {
        // get transaction count 
        // store transaction in the mapping
        // increment transaction count
        // emit an event
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            executed: false,
            destination: destination,
            value: value,
            data: data });
        transactionCount+=1;
        emit Submission(transactionId);
    }
}
