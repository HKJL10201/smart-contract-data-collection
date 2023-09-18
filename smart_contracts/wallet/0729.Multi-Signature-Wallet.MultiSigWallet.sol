// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title MultiSig
 * @dev A multi-signature wallet contract that requires multiple owners to confirm and execute transactions.
 */
contract MultiSig {
    address[] public owners; // Array of addresses representing the owners of the wallet
    uint256 public numConfirmationsRequired; // Number of confirmations required to execute a transaction

    struct Transaction {
        address to; // Address of the receiver
        uint256 value; // Amount of Ether to be transferred
        bool executed; // Flag indicating if the transaction has been executed
        bool isRejected; // Flag indicating if the transaction has been rejected
    }

    mapping(uint256 => mapping(address => bool)) isConfirmed; // Mapping to track confirmation status of each transaction by each owner
    mapping(uint256 => address) transactionOwner; // Mapping to track the owner who submitted each transaction
    mapping(uint256 => uint256) transactionAmount; // Mapping to track the amount of each transaction
    mapping(uint256 => bool) IsRejected; // Mapping to track rejection status of each transaction
    Transaction[] public transactions; // Array of all transactions submitted to the contract

    event TransactionSubmitted(
        uint256 transactionId,
        address sender,
        address receiver,
        uint256 amount
    ); // Event emitted when a transaction is submitted

    event TransactionConfirmed(uint256 transactionId); // Event emitted when a transaction is confirmed

    event TransactionExecuted(uint256 transactionId); // Event emitted when a transaction is executed

    modifier onlyOwner() {
        require(
            isOwner(msg.sender),
            "Only contract owners can call this function"
        );
        _;
    }

    /**
     * @dev Constructor function
     * @param _owners Array of addresses representing the owners of the wallet
     * @param _numConfirmationsRequired Number of confirmations required to execute a transaction
     */
    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        require(_owners.length > 1, "Owners Required Must Be Greater than 1");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "Num of confirmations are not in sync with the number of owners"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid Owner");
            owners.push(_owners[i]);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    /**
     * @dev Checks if an address is one of the owners of the wallet
     * @param account Address to be checked
     * @return Boolean indicating if the address is an owner
     */
    function isOwner(address account) public view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == account) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Submits a transaction to the contract
     * @param _to Address of the receiver
     */
    function submitTransaction(address _to) public payable {
        require(_to != address(0), "Invalid Receiver's Address");
        require(msg.value > 0, "Transfer Amount Must Be Greater Than 0");

        uint256 transactionId = transactions.length;
        transactionOwner[transactionId] = msg.sender;
        transactionAmount[transactionId] = msg.value;

        transactions.push(
            Transaction({
                to: _to,
                value: msg.value,
                executed: false,
                isRejected: false
        })
    );

    emit TransactionSubmitted(transactionId, msg.sender, _to, msg.value);
}

/**
 * @dev Confirms a transaction by an owner
 * @param _transactionId ID of the transaction to be confirmed
 */
function confirmTransaction(uint256 _transactionId) public onlyOwner {
    require(_transactionId < transactions.length, "Invalid Transaction Id");
    require(
        !isConfirmed[_transactionId][msg.sender],
        "Transaction Is Already Confirmed"
    );
    require(!IsRejected[_transactionId], "This transaction is rejected");

    isConfirmed[_transactionId][msg.sender] = true;
    emit TransactionConfirmed(_transactionId);

    if (isTransactionConfirmed(_transactionId)) {
        executeTransaction(_transactionId);
    }
}

/**
 * @dev Executes a confirmed transaction
 * @param _transactionId ID of the transaction to be executed
 */
function executeTransaction(uint256 _transactionId) internal {
    require(_transactionId < transactions.length, "Invalid Transaction Id");
    require(
        !transactions[_transactionId].executed,
        "Transaction is already executed"
    );

    (bool success, ) = transactions[_transactionId].to.call{
        value: transactions[_transactionId].value
    }("");
    require(success, "Transaction Execution Failed");

    transactions[_transactionId].executed = true;
    emit TransactionExecuted(_transactionId);
}

/**
 * @dev Checks if a transaction has received the required number of confirmations
 * @param _transactionId ID of the transaction to be checked
 * @return Boolean indicating if the transaction is confirmed
 */
function isTransactionConfirmed(uint256 _transactionId)
    internal
    view
    returns (bool)
{
    require(_transactionId < transactions.length, "Invalid Transaction Id");

    uint256 confirmationCount; // initially zero

    for (uint256 i = 0; i < owners.length; i++) {
        if (isConfirmed[_transactionId][owners[i]]) {
            confirmationCount++;
        }
    }

    return confirmationCount >= numConfirmationsRequired;
}

/**
 * @dev Rejects a transaction by the transaction owner
 * @param _transactionId ID of the transaction to be rejected
 */
function rejectTransaction(uint256 _transactionId) public {
    require(_transactionId < transactions.length, "Invalid Transaction Id");
    require(
        !isConfirmed[_transactionId][msg.sender],
        "Transaction Is Already Confirmed By The Owner"
    );
    require(
        transactionOwner[_transactionId] == msg.sender,
        "You are not the executor of this transaction"
    );

    payable(msg.sender).transfer(transactionAmount[_transactionId]);

    IsRejected[_transactionId] = true;
    transactions[_transactionId].isRejected = true;

    emit TransactionExecuted(_transactionId);
 }
}
