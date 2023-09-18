// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MultiSig {
    address[] public owners;
    uint public required;
    uint public txnid;
    mapping(uint=>mapping(address=>bool))  public confirmations;
    Transaction[] public transactions;
    struct Transaction {
        address _dest;
        uint   _value;
        bool executed;
        bytes data;
    }
    constructor(address[] memory _arr ,uint _req){
        owners=_arr;
        required=_req;
        require(owners.length>0 && required>0);
        require(required<=owners.length);
    }
  
    function addTransaction(address des, uint val,bytes memory _da) internal returns (uint){

        transactions.push(Transaction(des,val,false,_da));
         txnid=transactionCount()-1;
        return txnid;
    }
    function transactionCount() public view  returns(uint){
        return transactions.length;
    }
    function confirmTransaction(uint _id)  public {
        uint k=0;
        for(uint i=0;i<owners.length;i++){
            if(msg.sender==owners[i]){
                k=k+1;
            }
        }
        require(k>0);
        confirmations[_id][msg.sender]=true;
        if(isConfirmed(_id)==true){
                executeTransaction(_id);
        }
    }
    function getConfirmationsCount(uint  transactionId )  public view returns(uint){
        uint j=0;
        for(uint i=0;i<owners.length;i++){
        if(confirmations[transactionId][owners[i]]==true){
            j=j+1;
        }}
        return j;
    }
    function submitTransaction(address _final,uint  _value,bytes memory _dat) external {
        addTransaction(_final,_value,_dat);
        confirmTransaction(txnid);
    }
    receive() external payable{}
    function isConfirmed(uint id) public view returns(bool){ 

        uint l = getConfirmationsCount(id);
        if(l>=required) {return true;}
        else return false;
    }
    function executeTransaction(uint id) public {
        // require(isConfirmed(id)==true);
        (bool s,)=transactions[id]._dest.call{value:transactions[id]._value}(transactions[id].data);
        require(s,"Passed");
        transactions[id].executed=true;
    }
}
