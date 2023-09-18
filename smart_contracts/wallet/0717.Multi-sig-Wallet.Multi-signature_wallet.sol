// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MultiSigWallet{
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    struct Transaction{
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    address[] public owners;
    mapping(address=>bool) public isOwner;
    uint public required;

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;

    modifier onlyOwner(){
        require(isOwner[msg.sender], "You are not a owner");
        _;
    }
    modifier txExists(uint _txId){
      require(_txId < transactions.length, "Transaction already exists");
        _;
    }
    modifier notApproved(uint _txId){
       require(!approved[_txId][msg.sender], "Transaction already approved");
        _;
    }
    modifier notExecuted(uint _txId){
       require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }

    constructor(address[] memory _owners, uint _required){
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid required numbers of owners");

        for(uint i; i<_owners.length; i++){
            address owner = _owners[i];

            require(owner != address(0), "Owners required");
            require(!isOwner[owner],"Not a unique owner");

            isOwner[owner] = true;
            owners.push(owner);

        }
       required = _required;
    }

      receive()external payable{
          emit Deposit(msg.sender, msg.value);
      }

    function submit(address _to, uint _value, bytes calldata _data) external onlyOwner{
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        emit Submit(transactions.length - 1);
    }

    function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId){
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function getApprovalCount(uint _txId) private view returns(uint count){
        for(uint i; i<owners.length; i++){
            if(approved[_txId][owners[i]]){
                count += 1;
            }
        }
    }

    function execute(uint _txId) external txExists(_txId) notExecuted(_txId) {
        require(getApprovalCount(_txId) >= required, "Approvals for the transaction are less than required");
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction failed");

        emit Execute(_txId);
    }

    function revoke(uint _txId) external txExists(_txId) notApproved(_txId) {
        require(approved[_txId][msg.sender], "transaction has not been approved by you");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}