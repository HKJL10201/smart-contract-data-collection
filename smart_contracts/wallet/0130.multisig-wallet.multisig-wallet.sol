pragma solidity ^0.8.0;

contract MultiSigWallet {

    // function events
    event Deposit(address indexed sender, uint amount);
    event SubmitTransaction (uint indexed txIndex);
    event ApproveTransaction(address indexed owner, uint indexed txIndex);
    event RevokeApproval(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    //******** STATE VARIABLES *******//
    // store owners in array of addresses
    address[] public owners;

    // mapping to check if user is owner or not
    mapping(address => bool) public isOwner;

    // store number of approvals required to execute a transaction
    uint public numApprovalsRequired;

    // when a transaction is proposed by calling the submit transaction function we create a struct called Transaction
    struct Transaction {
        address to; // address transaction is sent to
        uint value; // amount of ether to send to address
        bytes data; // in the case of calling another contract we store the transaction data sent to that contract
        bool executed; // boolean value indicating whether transaction is executed or not

        uint numApprovals; // store number of approvals in num approvals
    }

    // store struct in array of transactions
    Transaction[] public transactions;

    // when a user approves transaction it is stored in a mapping from address to boolean
    mapping(uint => mapping(address => bool)) public approved;

    //******** END OF STATE VARIABLES *******//

    // constructor to initialize state variables
    constructor(address[] memory _owners, uint _numApprovalsRequired) {

        // check that array of owners is not empty
        require(_owners.length > 0, "owners required");

        // number of approvals required is greater than zero
        // and less than or equal to number of owners
        require(_numApprovalsRequired > 0 && _numApprovalsRequired <= _owners.length, "invalid number of required approvals");

        // copy owners from input to state variable
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            // make sure owner is not equal to zero address
            require(owner != address(0), "invalid owner");

            // ensure that there are no duplicate owners
            require(!isOwner[owner], "owner is not unique");

            isOwner[owner] = true;

            // add owner to the owners state variable
            owners.push(owner);

        }

        numApprovalsRequired = _numApprovalsRequired;
    }

    //******** Modifiers *******//
    // checks if transaction exists by checking if the transaction index is less than transaction length
    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    // Check if transaction has not executed by getting transaction at txIndex and make sure the executed field is set to false
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    // check if transaction is not approved by checking the approved mapping
    modifier notApproved(uint _txIndex) {
        require(!approved[_txIndex][msg.sender], "tx already approved");
        _;
    }

    // check if user is owner of the wallet and throw error if false and execute if true
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    //******** End Of Modifiers *******//

    // send ether function
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }


    // Propose a transaction that must be approved by other owners by calling submitTransaction func()
    // here we use calldata instead of memory because this function is external and calldata is cheaper on gas
    function submitTransaction(address _to, uint _value, bytes calldata _data) external onlyOwner {

        transactions.push(Transaction({
        to: _to,
        value: _value,
        data: _data,
        executed: false,
        numApprovals: 0
        }));

        // emit submit transaction event
        emit SubmitTransaction(transactions.length - 1);
    }



    // Owners can approve transaction by calling approveTransaction func()
    function approveTransaction(uint _txIndex) external onlyOwner txExists(_txIndex) notApproved(_txIndex) notExecuted(_txIndex) {

        // set is confirmation for msg.sender to true
        approved[_txIndex][msg.sender] = true;

        // emit an event with sender and index of transaction approved
        emit ApproveTransaction(msg.sender, _txIndex);
    }

    // get approval account
    function _getApprovalCount(uint _txId) private view returns (uint count) {
        for (uint i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    // if enough owners approve the transaction then executeTransaction func() can be called
    function executeTransaction(uint _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {

        // check if there are enough approvals to execute transaction
        require(_getApprovalCount(_txIndex) >= numApprovalsRequired, "cannot execute transaction");

        // get transaction at index
        Transaction storage transaction = transactions[_txIndex];

        // if confirmation threshhold has been reached set executed to true
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);

        // check if execute transaction call was successful
        require (success, "transaction failed");

        // emit execute transaction event with the owner that called this function and the transaction id
        emit ExecuteTransaction(msg.sender, _txIndex);

    }

    // owner can revoke transaction by calling revokeApproval func()
    function revokeApproval(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {

        // first get transaction at index
        Transaction storage transaction = transactions[_txIndex];

        // check if transaction is approved
        require(approved[_txIndex][msg.sender], "tx not approved");

        // If transaction has been approved set confirmation to false
        approved[_txIndex][msg.sender] = false;

        // Reduce number of approvals by 1
        transaction.numApprovals -= 1;

        // emit Revoke Approval event with the owner that called this function and the transaction id
        emit RevokeApproval(msg.sender, _txIndex);

    }
}
