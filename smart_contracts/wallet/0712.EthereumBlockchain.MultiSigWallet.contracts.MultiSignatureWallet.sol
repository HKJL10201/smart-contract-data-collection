pragma solidity ^0.4.15;

contract MultiSignatureWallet {

    struct Transaction {
		bool executed;
    	address destination;
    	uint value;
    	bytes data;
    }

    mapping (uint => Transaction) transactionList;
    uint currentId;

    mapping (uint => mapping (address => bool)) confirmations;

    address[] owners;
    uint required;



    /// @dev Fallback function, which accepts ether when sent to contract
    function() public payable {}

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    function MultiSignatureWallet(address[] _owners, uint _required) public {
    	owners = _owners;
    	required = _required;

    	currentId = 0;
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data) public returns (uint transactionId) {
    	transactionList[currentId] = Transaction({executed: false, destination: destination, value: value, data: data});
    	confirmations[currentId][msg.sender] = true;
    	currentId++;
    	return (currentId-1);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId) public {
    	confirmations[transactionId][msg.sender] = true;
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId) public {
    	confirmations[transactionId][msg.sender] = false;
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId) public {
    	uint c = 0;
    	for (uint i = 0; i < owners.length; i++) {
    		if (confirmations[transactionId][owners[i]]) {
    			c++;
    		}
    	}
    	require(c >= required);

    	address to = transactionList[transactionId].destination;
    	uint val = transactionList[transactionId].value;
    	uint d = transactionList[transactionId].data;

    	transactionList[transactionId].executed = true;

    	to.call.value(val)(d);
    	
    }

		/*
		 * (Possible) Helper Functions
		 */
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId) internal constant returns (bool) {
    	return transactionList[transactionId].executed;
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes data) internal returns (uint transactionId) {
    	return 0;
    }
}
