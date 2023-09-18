// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);
    event Cancel(uint indexed txId);
    event AddOwner(address indexed owner);
    event RemoveOwner(address indexed owner);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint expiresAfter;
        bool cancelled;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;
    mapping(uint => mapping(address => uint)) public approvalTimestamp;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notApproved(uint _txId) {
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    modifier notCancelled(uint _txId) {
        require(!transactions[_txId].cancelled, "tx already cancelled");
        _;
    }

    modifier notExpired(uint _txId) {
        require(block.timestamp < transactions[_txId].expiresAfter, "transaction has expired");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(
            _required > 0 && _required <= _owners.length,
            "invalid required number of owners"
        );

        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint _value, bytes calldata _data, uint _expiresAfter) external onlyOwner {
        require(_expiresAfter > 0, "expiration time must be greater than 0");

        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            expiresAfter: block.timestamp + _expiresAfter,
            cancelled: false
        }));
        emit Submit(transactions.length - 1);
    }

    function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId) notExpired(_txId) {
        approved[_txId][msg.sender] = true;
        approvalTimestamp[_txId][msg.sender] = block.timestamp;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint _txId) private view returns (uint count) {
        for (uint i; i < owners.length; i++) {
            if(approved[_txId][owners[i]]) {
                count += 1;
            }
        }

        return count;
    }

    function execute(uint _txId) external txExists(_txId) notExecuted(_txId) notCancelled(_txId) notExpired(_txId) {
        require(_getApprovalCount(_txId)>= required, "approvals < required");
        Transaction storage transaction = transactions[_txId];

        transaction.executed = true;

       (bool success, ) = transaction.to.call{value: transaction.value} (transaction.data);
       require(success, "tx failed");

       emit Execute(_txId);
    }

    function cancel(uint _txId) external txExists(_txId) onlyOwner notExecuted(_txId) notCancelled(_txId) notExpired(_txId) {
        Transaction storage transaction = transactions[_txId];
        transaction.cancelled = true;

        emit Cancel(_txId);
    }

    function addOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "invalid owner");
        require(!isOwner[_owner], "owner already exists");

        isOwner[_owner] = true;
        owners.push(_owner);
        emit AddOwner(_owner);
    }

    function removeOwner(address _owner) external onlyOwner {
        require(isOwner[_owner], "owner does not exists");
        require(owners.length - 1 >= required, "cannot remove owner, minimum number of owners reached");

        isOwner[_owner] = false;
        for (uint i; i < owners.length - 1; i++) {
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.pop();

        emit RemoveOwner(_owner);
    }

    function revoke(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) notExpired(_txId) notCancelled(_txId) {
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}