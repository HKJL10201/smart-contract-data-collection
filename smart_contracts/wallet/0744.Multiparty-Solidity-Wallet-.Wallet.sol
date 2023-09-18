// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Wallet {


    // These events will be emited when various functions are called

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

    address private administrator;              //These is the administrator of the contract
    address[] public owners;                    //An array of all owners 
    mapping(address => bool) public isOwner;    //A mapping to verify the status of an address as an owner
    uint private requiredApprovals;             // Number of required approvals for a transaction to be executed
    uint private requiredApprovalPercentage;    // Percentage of required approvals set by administrator
    address private transactionProposer;        // This stores the address of the last owner to propose a transaction
    uint private totalOwners;                   // This stores the lenght of the owner array multiplied by 10 to account for arithmetic float points
 
    
    // A struct containing the details of every proposed transaction
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint Approvals;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) private isApproved;

    // An array of the Transaction structs
    Transaction[] private transactions;

    // Modifier to check if sender of function is an owner
    modifier onlyOwners() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    // Modifier to check if the sender of the function is the administrator
    modifier onlyAdministrator () {
        require(msg.sender == administrator, "Only administrator can call this function");
        _;
    }

    // Modition to check if the transaction index exists
    modifier transactionProposed(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    // Modifier to check is the transaction has been precviously executed
    modifier TransactionNotExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    //  Modifier to check is the transaction has been previously approved by msg.sender
    modifier TransactionNotSigned(uint _txIndex) {
        require(!isApproved[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    // Modition to check if the sender of the function is the same as the contract proposer
    modifier onlyTransactionProposer() {
        require(msg.sender == transactionProposer, "Only transaction Proposer can call function");
        _;
    }



    // Constructor sets the msg.sender as the contract administrator upon deployment
    // Takes an input of addresses that are passed into the owners array
    // At least two addresses must be passed into the owners array
    // The number of required Approvals is set to 60% of the lenght of owners array and multiplied by 10 to cover for arithmetic float points

    constructor(address[] memory _owners) {
        administrator = msg.sender;
        

        require(_owners.length > 1, "owners required");
        

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        requiredApprovalPercentage = 60;

        TotalOwners();

        requiredApprovals = ((requiredApprovalPercentage * totalOwners) / 100);


        
    }

    // External function that can be called to deposit
    // Emits the Deposit event
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // Function that allows owners to propose transactions
    // Stores the address of the transaction proposer into a state variable
    // Emits the SubmitTransaction event
    function proposeTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwners {
        uint txIndex = transactions.length;

        transactionProposer = msg.sender;
    

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                Approvals: 0
            })
        );

       
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }
    

    // Function that allows owners to approve a transaction 
    // Requires that the transaction proposer cannot approve the transaction
    // Passes the transaction details into the Transaction struct, and stored into the Transaction array with a transaction index
    // Emits the ConfirmTransaction event
    function approveTransaction(uint _txIndex)
        public
        onlyOwners
        transactionProposed(_txIndex)
        TransactionNotExecuted(_txIndex)
        TransactionNotSigned(_txIndex)
    {
        require(msg.sender != transactionProposer );

        Transaction storage transaction = transactions[_txIndex];
        transaction.Approvals += 1;
        isApproved[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    // Function allows the proposer of the transaction to execute the transaction
    // Requires that the transaction approval is equal or greater than the required approvals
    // Only the contract proposer can call the function
    // Emits the ExecuteTransaction events
    function executeTransaction(uint _txIndex)
        public
        onlyTransactionProposer
        transactionProposed(_txIndex)
        TransactionNotExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            (transaction.Approvals * 10) >= requiredApprovals,
            "cannot execute transaction"
        );

        transaction.executed = true;

        transaction.to.call{value: transaction.value}(
            transaction.data
        );
       

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    // Function allows a owner to revoke their confirmation on a transaction
    // Requires that the owner has previously apporved the transaction
    // Emits the RevokeTransaction event
    function revokeConfirmation(uint _txIndex)
        public
        onlyOwners
        transactionProposed(_txIndex)
        TransactionNotExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isApproved[_txIndex][msg.sender], "transaction not confirmed");

        transaction.Approvals -= 1;
        isApproved[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    // Public function to view the total number of transactions
    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    // Public function to view the detials of a transaction via its index
    function getTransactionDetails(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint Approvals
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.Approvals
        );
    }

    // Function to a new a owner to the array of owners
    function addOwner(address _newOwner) private onlyAdministrator {
          owners.push(_newOwner);
          TotalOwners();
          requiredApprovals = ((requiredApprovalPercentage * totalOwners) / 100);


    }

    // Function to remove a owner from the array of owners
    function removeOwner(uint _ownerId) private onlyAdministrator {
        delete owners[_ownerId];
        TotalOwners();
        requiredApprovals = ((requiredApprovalPercentage * totalOwners) / 100);
    }

    // Internal function that gets the total number of owners and multiplies by 10 to account for arithmetic float points
    function TotalOwners() internal returns (uint) {
        totalOwners = owners.length * 10;
        return totalOwners;
        
    }

    // Function used to set the required number of apporvals
    // Function can only be called by the contract administrator
    function setReuiredApproval (uint _requiredApprovalPercentage) private onlyAdministrator {
        requiredApprovalPercentage = _requiredApprovalPercentage;
        TotalOwners();
        requiredApprovals = ((requiredApprovalPercentage * totalOwners) / 100);
    }
}

