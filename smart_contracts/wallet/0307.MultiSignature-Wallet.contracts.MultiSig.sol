// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MultiSig {
    // State variables
    // Array of addresses of all Owners
    address[] public owners;
    // To check that the caller of the function is msg.sender
    mapping(address => bool) public isOwner;
    // No of approval needed to complete the tx
    uint256 public requiredApprovals;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }
    Transaction[] public transactions;

    // Tx will be executed if the no of approvals is greater than or equal to requiredArrovals
    // Storing the arroval of each tx by each owner
    // Index of Tx => address of owner => Arroved or Not
    mapping(uint256 => mapping(address => bool)) public approved;

    // Events
    event Deposited(address indexed sender, uint256 amount);
    event Submited(uint256 indexed txId);
    event Approved(address indexed owner, uint256 indexed txId);
    event Revoked(address indexed owner, uint256 indexed txId);
    event Executed(uint256 txId);

    // Errors
    error LESS_NO_OF_OWNERS();
    error INVALID_OWNER();
    error NOT_UNIQUE_OWNER();
    error NOT_OWNER();

    // Modifiers
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) {
            revert NOT_OWNER();
        }
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "Tx does not exist");
        _;
    }

    modifier notApproved(uint256 _txId) {
        require(!approved[_txId][msg.sender], "Tx already approved");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Tx already executed");
        _;
    }

    // Constructor

    constructor(address[] memory _owners, uint256 _requiredApprovals) {
        if (_owners.length <= 1) {
            revert LESS_NO_OF_OWNERS();
        }
        require(
            _requiredApprovals > 0 && _requiredApprovals <= _owners.length,
            "Invalid no of Approvals"
        );
        for (uint256 i; i < _owners.length; i++) {
            address owner = _owners[i];
            if (owner == address(0)) {
                revert INVALID_OWNER();
            }
            // Check if owner is already present
            if (isOwner[owner]) {
                revert NOT_UNIQUE_OWNER();
            }
            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredApprovals = _requiredApprovals;
    }

    // Functions

    function submit(
        address _to,
        uint256 _value,
        bytes memory _data,
        bool _executed
    ) external onlyOwner {
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: _executed
            })
        );
        emit Submited(transactions.length);
    }

    function approve(
        uint256 _txId
    ) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId) {
        approved[_txId][msg.sender] = true;
        emit Approved(msg.sender, _txId);
    }

    // To get the no of approval on a given tx id
    function getApprovalCount(
        uint256 _txId
    ) private view returns (uint256 count) {
        // For each owner we will check if approved is true or not
        // If it is true, increase the count by 1
        for (uint256 i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    function execute(
        uint256 _txId
    ) external txExists(_txId) notExecuted(_txId) {
        require(
            getApprovalCount(_txId) >= requiredApprovals,
            "Approval is less than required"
        );
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed!");
        emit Executed(_txId);
    }

    function revoke(
        uint256 _txId
    ) external payable onlyOwner txExists(_txId) notExecuted(_txId) {
        require(approved[_txId][msg.sender], "Tx not approved");
        approved[_txId][msg.sender] = false;
        emit Revoked(msg.sender, _txId);
    }

    // To be able to receive ETH
    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }
}
