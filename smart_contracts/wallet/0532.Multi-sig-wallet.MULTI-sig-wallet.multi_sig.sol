//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.16;

contract Multisig{

    event Deposit(address indexed sender,uint amount);
    event Submit(address indexed from,address indexed to,uint value,uint indexed txId);
    event Approve(address indexed owner,uint txId);
    event Revoke(address indexed owner,uint txId);
    event Execute(uint indexed txId,uint indexed approvals);

    address[] public owners;
    mapping(address => bool) public ISowner;
    uint public required;   //no. of owners reqrd to approve a transaction 

    struct Transaction {
        address to;
        uint value;
        bytes data;
        uint approvals; // no. of owners approved this tx
        bool executed;
    }
    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;

    constructor(address[] memory _owners,uint _required){

        require(_owners.length > 0,"not enough owners");
        require(_required >0 && _required <= _owners.length,"wrong requirement value");

        for(uint i=0; i <_owners.length;i++){
            address owner = _owners[i];
            require(owner != address(0),"enter non-zer0 address");
            require(ISowner[owner] != true,"already a owner");

            owners.push(owner);
            ISowner[owner] = true;
            required = _required;
        }
    }

    modifier OnlyOwner(){
        require(ISowner[msg.sender] == true,"you cant inititate transaction" );
        _;
    }
    modifier txIdExist(uint _txId){
        require(_txId < transactions.length,"tx doesnot exist");
        _;
    }
    modifier notApproved(uint _txId){
        require(approved[_txId][msg.sender] == false,"already approved");
        _;
    }
    modifier notExecuted(uint _txId){
        require(transactions[_txId].executed != true,"already executed");
        _;
    }
    modifier txApproved(uint _txId){
        require(approved[_txId][msg.sender] == true,"tx not approved yet");
        _;
    }

    receive() external payable{
        emit Deposit(msg.sender,msg.value);
    }

    function submit(address _to,uint _value,bytes calldata _data ) external OnlyOwner{
        transactions.push(Transaction({
            to:_to,
            value:_value,
            data:_data,
            approvals : 0,
            executed: false
        }));

        emit Submit(msg.sender, _to, _value, transactions.length -1);
    }

    function approve(uint _txId) external OnlyOwner txIdExist(_txId) notApproved(_txId) notExecuted(_txId) {
        approved[_txId][msg.sender] = true;
        transactions[_txId].approvals +=1 ;

        emit Approve(msg.sender,_txId);
    }

    function revoke(uint _txId) external OnlyOwner txApproved(_txId) notExecuted(_txId){
        approved[_txId][msg.sender] = false;
        transactions[_txId].approvals -= 1;

        emit Revoke(msg.sender,_txId);
    }

    function execute(uint _txId) external OnlyOwner  txIdExist(_txId) txApproved(_txId) {
        require(transactions[_txId].approvals >= required);
        transactions[_txId].executed = true;

        (bool etherSENT,  ) = (transactions[_txId].to).call{value:(transactions[_txId].value)}(transactions[_txId].data);
        require(etherSENT,"TX_failed");

        emit Execute(_txId,transactions[_txId].approvals);
    }

}
