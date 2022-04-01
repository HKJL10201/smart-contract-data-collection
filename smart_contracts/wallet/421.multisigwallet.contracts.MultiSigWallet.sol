// SPDX-License-Identifier: MIT.
pragma solidity ^0.8.7;

/// @title Multi signature Wallet.
/// @author Esteban Hugo Somma.
/// 
/// @notice A MultiSig wallet is a digital wallet that operates with multisignature 
/// addresses. This means that it requires more than one private key to sign and 
/// authorize a crypto transaction.
contract MultiSigWallet {
    //#region Declarations

    // Fires when the contract receives ethers.
    event Deposit(address indexed sender, uint amount, uint balance);
    // Fires when a new transaction is generated pending confirmation and execution.
    event SubmitTransaction(address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data);
    // Fires when an owner confirms the pending transaction.
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    // Fires when an owner revokes a transaction previously confirmed by himself.
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    // Se dispara cuando un propietario ejecuta una transacción confirmada.
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    // List of owners of the wallet.
    address[] public owners;

    // Mapping to check if the address is a registered owner of the wallet.
    mapping(address => bool) public isOwner;
    
    // Number of confirmations required on the number of owners of the wallet so 
    // that a pending transaction can be executed.
    uint public numConfirmationsRequired;

    // Transaction data.
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    // Mapping from tx index => owner => bool.
    // It stores the confirmation status of all the owners accounts for each transaction.
    // 
    //  tx[0] =>
    //   └┬──owner[0] => true (confirmed)
    //    ├──owner[1] => false (unconfirmed yet)
    //    └──owner[n] => false (unconfirmed yet)
    mapping(uint => mapping(address => bool)) public isConfirmed;

    // List of transactions.
    Transaction[] public transactions;

    // Modifier that requires the sender to be in the list of wallet owners.
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    // Modifier that requires the transaction index to be an existent transaction.
    modifier txExists(uint txIndex) {
        require(txIndex < transactions.length, "Tx does not exist");
        _;
    }

    // Modifier that requires that the transaction corresponding to {txIndex} has 
    // not been executed.
    modifier notExecuted(uint txIndex) {
        require(!transactions[txIndex].executed, "Tx already executed");
        _;
    }

    // Modifier that requires that the transaction corresponding to {txIndex} has 
    // not been previously confirmed by the {sender}.
    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "Tx already confirmed");
        _;
    }

    //#endregion

    //#region Constructor

    /// @dev Sets the values for {owners_} and {numConfirmationsRequired_}. These 
    /// are immutable, they can only be set once during construction.
    /// 
    /// @param owners_ A list of the owners addresses.
    /// @param numConfirmationsRequired_ Cantidad de confirmaciones (direcciones) 
    ///     requeridas para poder ejecutar una transacción.
    ///
	/// Requirements:
	/// - `owners_` Must have at least one address.
    /// - `numConfirmationsRequired_` Must be greater than 0 and less than or equal 
    ///   to the number of owners.
    /// - Owners addreses should not be zero address.
    /// - Owners addreses should not be duplicated in the owners list.
    constructor(address[] memory owners_, uint numConfirmationsRequired_) {
        require(owners_.length > 0, "Owners required");
        require(
            numConfirmationsRequired_ > 0 &&
            numConfirmationsRequired_ <= owners_.length,
            "To much confirmations"
        );

        for (uint i = 0; i < owners_.length; i++) {
            address owner = owners_[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = numConfirmationsRequired_;
    }

    //#endregion

    //#region Public functions

    /// @notice // Function to receive ethers. msg.data must be empty.
    /// 
    /// Emits an {Deposit} event.
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /// @notice Create a new pending transaction to then be committed and executed.
    /// 
    /// @param to_ The destination address (address or contract).
    /// @param value_ The value to be transferred in the transaction in wei.
    /// @param data_ The data to be transferred in the transaction in bytes.
    /// 
    /// Emits an {SubmitTransaction} event.
    /// 
    /// Requirements:
    /// - `sender` Must be one of the owners of the wallet.
    ///
    /// Example: 
    /// 0x8Fc6AC3855Ace6776DA2a2621425d8bb6976Da33,1000000000000000000,0x000000
    function submitTransaction(address to_, uint value_, bytes memory data_) 
        external onlyOwner 
    {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: to_,
                value: value_,
                data: data_,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, to_, value_, data_);
    }

    /// @notice Sets the owner confirmation in the transaction corresponding to 
    /// specified {txIndex}.
    /// 
    /// @param txIndex The transaction index.
    /// 
    /// Emits an {ConfirmTransaction} event.
    /// 
    /// Requirements:
    /// - `sender` Must be one of the owners of the wallet.
    /// - `txIndex` Corresponds to an existng transaction. 
    /// - `txIndex` Must be the index of a transaction not yet executed.
    /// - `txIndex` Must be the index of a transaction not yet confirmed.
    function confirmTransaction(uint txIndex)
        external
        onlyOwner
        txExists(txIndex)
        notExecuted(txIndex)
        notConfirmed(txIndex)
    {
        Transaction storage transaction = transactions[txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, txIndex);
    }

    /// @notice Executes the transaction corresponding to specified {txIndex}.
    /// 
    /// @param txIndex The transaction index.
    /// 
    /// Emits an {ExecuteTransaction} event.
    /// 
    /// Requirements:
    /// - `sender` Must be one of the owners of the wallet.
    /// - `txIndex` Corresponds to an existng transaction. 
    /// - `txIndex` Must be the index of a transaction not yet executed.
    /// - The transaction to execute must have all the required confirmations.
    function executeTransaction(uint txIndex)
        external
        onlyOwner
        txExists(txIndex)
        notExecuted(txIndex)
    {
        Transaction storage transaction = transactions[txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "Unconfirmed transaction yet"
        );

        transaction.executed = true;

        // NOTE: There is no risk to get reentrant here.
        // - onlyOwner modifier.
        // - notExecuted midifier.
        
        // solhint-disable-next-line
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Tx failed");

        emit ExecuteTransaction(msg.sender, txIndex);
    }

    /// @notice Revokes the transaction corresponding to specified {txIndex} that 
    /// has previously been confirmed by the sender.
    /// 
    /// @param txIndex The transaction index.
    /// 
    /// Emits an {RevokeConfirmation} event.
    /// 
    /// Requirements:
    /// - `sender` Must be one of the owners of the wallet.
    /// - `txIndex` Corresponds to an existng transaction. 
    /// - `txIndex` Must be the index of a transaction not yet executed.
    /// - `txIndex` Must be the index of a transaction previously confirmed by the 
    ///   sender.
    function revokeConfirmation(uint txIndex)
        external
        onlyOwner
        txExists(txIndex)
        notExecuted(txIndex)
    {
        Transaction storage transaction = transactions[txIndex];

        require(isConfirmed[txIndex][msg.sender], "Tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, txIndex);
    }

    /// @notice Gets the list of owners addresses.
    /// @return The list of owners.
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    /// @notice Gets the transactions count.
    /// @return The transactions count.
    function getTransactionCount() external view returns (uint) {
        return transactions.length;
    }

    /// @notice Gets the properties of the transaction corresponding to specified {txIndex}.
    /// 
    /// @param txIndex The transaction index.
    /// 
    /// @return to Transaction property.
    /// @return value Transaction property.
    /// @return data Transaction property.
    /// @return executed Transaction property.
    /// @return numConfirmations Transaction property.
    function getTransaction(uint txIndex)
        external
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    //#endregion
}
