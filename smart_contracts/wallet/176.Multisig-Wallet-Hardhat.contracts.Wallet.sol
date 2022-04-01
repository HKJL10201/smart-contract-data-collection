//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Wallet {
    
    //vars
    address[] public approvers;
    uint public quorum;
    struct Transfer { //structs goes with upper case
        uint id;
        uint amount;
        address payable to;
        uint approvals;
        bool sent;
    }
    Transfer[] public transfers; //array of all transfers
    mapping(address => mapping(uint => bool)) approvals; //which address has approved (or not) every transfer

    constructor(address[] memory _approvers, uint _quorum){
        approvers = _approvers;
        quorum = _quorum;
    }

    //modifiers

    modifier onlyApprover() {
        bool allowed = false;
        for(uint i=0; i < approvers.length; i++){
            if(approvers[i] == msg.sender){
                allowed = true;
            }
        }
        require(allowed == true, "only approvers are allowed to access");
        _;
    }

    modifier positiveBalance() {
        require(address(this).balance != 0, "The balance is empty");
        _;
    }

    //functions

    function getApprovers() external view returns(address[] memory){
        return approvers; //view to access state var and not modify it
    }

    function getTransfers() external view returns(Transfer[] memory){
        return transfers; //view to access state var and not modify it
    }

    function createTransfer(uint amount, address payable to) onlyApprover positiveBalance external {
        transfers.push(Transfer(
            transfers.length,
            amount,
            to,
            0,
            false
        ));
    }

    function approveTransfer(uint id) onlyApprover positiveBalance external payable{
        //if the following require statements returns false, an error is returned
        require(transfers[id].sent == false, "transfer has already been sent");
        require(approvals[msg.sender][id] == false, "cannot approve transfer twice");

        approvals[msg.sender][id] = true;
        transfers[id].approvals++;

        if(transfers[id].approvals >= quorum){ //once the transfer has enought approvals, it is sended to the specified address
            transfers[id].sent = true;
            address payable to = transfers[id].to;
            uint amount = transfers[id].amount;
            to.transfer(amount);
        }
    }

    receive() external payable{} //the contract is enable to receive Ether


}