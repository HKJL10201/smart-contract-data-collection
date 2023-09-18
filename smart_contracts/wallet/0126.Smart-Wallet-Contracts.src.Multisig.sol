// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.18;
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/access/Ownable.sol";

contract MultiSig is Ownable{

    event deposit(address indexed sender, uint amount, uint balance);
    event SendTX(address indexed owner,uint indexed txindex,address indexed to,uint value,bytes data);
    event ConfirmTransaction(address indexed owner,uint indexed txindex);
    event RevokeCnfirmation(address indexed owner,uint indexed txindex);
    event ExecuteTransaction(address indexed owner,uint indexed txindex);

    mapping(address=>bool) public added;
    address[] public owners;
    uint public ConfirmationsRequired;

    struct Transaction{
    address to;
    uint value;
    bytes data;
    bool executed;
    mapping(asddress=>bool) isConfirmed;
    uint numconfirmations;
    }

    Transaction[] public transactions;



constructor(address[] memory _owners,uint _ConfirmationsRequired)public{
require(_owners.length>0,"no owners");
require(_ConfirmationsRequired > 0 && _ConfirmationsRequired < = _owners.length,"invalid number");

for(uint256=0;i<_owners.length;i++){
    address owner = _owners[i];
    require( owner =! owners(0),"invalid address");
    require(added[owner]==false,"owner already added");
    added[owner]=true;
}
ConfirmationsRequired = _ConfirmationsRequired;

}

modifier notconfirmed(uint256 _txindex){
    require(transactions[_txindex].isConfirmed == false,"transction already confirmed");
    _;
}

modifier NotExecuted(uint256 _txindex){
    require(transactions[_txindex].executed == false,"transction already executed");
    _;
}

modifier TXExists(uint256 _txindex){
    require(_txindex < transactions.length,"transction does not exist");
    _;
}



function SubmitTransaction(addres _to, uint256 _value,bytes memory _data) external onlyOwner{
    uint256 txindex = transactions.length;
// pushes transaction to array of proposed transactions
    transactions.push(Transaction({
        to:_to;
        value:_value;
        data:_data;
        executed:false;
        numconfirmations:0;
    }));
    emit SendTX(msg.sender,txindex ,_to,_value,_data);

}

function ConfirmTransaction(uint _txindex) external onlyOwner 
NotExecuted(_txindex)
 notconfirmed(_txindex)
 TXExists(_txindex){
Transaction storage transaction = transactions[_txindex];
transaction.isConfirmed[msg.sender]=true;
}
}