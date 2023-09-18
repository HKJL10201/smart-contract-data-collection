// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MutiSigWallet {
    event EthReceived(address indexed sender, uint amount, uint balance); // Event that would be log when Eth is sent to the Contract address

    event CreateTransaction(
        address indexed owner,
        uint indexed txNounce,
        address indexed to,
        uint value,
        bytes data
    );

    event AuthorizeTransaction(address indexed owner, uint indexed txNounce);
    event RevokeAuthorization(address indexed owner, uint indexed txNounce);
    event ExecuteTransaction(address indexed owner, uint indexed txNounce);

    address[] public owners;
    mapping(address => bool) isOwner;
    uint public numAuthorizationRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numAuthorization;
    }

    Transaction[] public transactions;

    mapping(uint => mapping(address => bool)) public ownerHasConfrimed;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not Owner");
        _;
    }

    modifier txExist(uint _txNounce) {
        require(_txNounce < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint _txNounce) {
        require(
            !transactions[_txNounce].executed,
            "Transaction already executed"
        );
        _;
    }

    modifier ownerNotComfirmed(uint _txNounce) {
        require(
            !ownerHasConfrimed[_txNounce][msg.sender],
            "Owner has already confrimed"
        );
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "Owners Required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "Invalid Number of Confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid Address Type");
            require(!isOwner[owner], "Duplicate Onwer Address");
            isOwner[owner] = true;
            owners.push(owner);
        }
        numAuthorizationRequired = _numConfirmationsRequired;
    }

    function createTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner returns (bool) {
        uint txNounce = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numAuthorization: 1
            })
        );

        ownerHasConfrimed[txNounce][msg.sender] = true;
        emit CreateTransaction(msg.sender, txNounce, _to, _value, _data);
        return true;
    }

    function authorizeTransaction(
        uint _txNounce
    )
        public
        onlyOwner
        txExist(_txNounce)
        notExecuted(_txNounce)
        ownerNotComfirmed(_txNounce)
    {
        Transaction storage transaction = transactions[_txNounce];
        transaction.numAuthorization += 1;
        ownerHasConfrimed[_txNounce][msg.sender] = true;

        emit AuthorizeTransaction(msg.sender, _txNounce);
    }

    function executeTransaction(
        uint _txNounce
    ) public onlyOwner txExist(_txNounce) notExecuted(_txNounce) {
        Transaction storage transaction = transactions[_txNounce];
        require(
            transaction.numAuthorization >= numAuthorizationRequired,
            "Tx not fully Authorized"
        );
        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "Transaction failed");

        emit ExecuteTransaction(msg.sender, _txNounce);
    }

    receive() external payable {
        emit EthReceived(msg.sender, msg.value, address(this).balance);
    }

    function getTransactionDetails(
        uint _txNounce
    )
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numAuthorization
        )
    {
        Transaction memory transaction = transactions[_txNounce];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numAuthorization
        );
    }

    function AddressIsOwner(address _address) public view returns (bool) {
        return isOwner[_address];
    }
}
