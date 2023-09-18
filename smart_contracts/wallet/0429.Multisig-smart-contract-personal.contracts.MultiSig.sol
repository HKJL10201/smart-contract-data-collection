// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MultiSig {
    address[] public approvers; //These are the addresses that can approve a transaction
    uint public approvalNum; //The minimum number of addresses that you need to approve a transaction

    struct Transfer {
        uint id;
        uint amount;
        address payable to;
        uint approvals;
        bool sent;
    }

    mapping(uint => Transfer) public transfers; //This is a container that takes and id and returns a struct, the struct is used to create a transfer
    uint nextId; //The id to keep track of the transfer
    mapping(address => mapping(uint => bool)) approvals; //This makes sure that an address can only approves a particular struct once


    //In the constructor, we specify the addresses that can approve a transaction and the minimum number needed
    constructor(address[] memory _approvers, uint _approvalNum) 
        payable {
        approvers = _approvers;
        approvalNum = _approvalNum;
    }


    //In the createTranfer function, we pass the amount to be sent and the recipient address
    //Only the approved addresses can create a transfer
    function createTransfer(uint amount, address payable to) external onlyApprover() {
        transfers[nextId] = Transfer(
            nextId,
            amount,
            to,
            0,
            false
        );
        nextId++; //The next id is incremented so as to uniquely identify the struct
    }


    //Here, we pass the id of the struct we want to send
    //The struct has the amount and the receipient address
    function sendTransfer(uint id) external onlyApprover() {
        require(transfers[id].sent == false, "transfer has already been sent"); //We require that the transfer sent property should be false
        

        //Here, we check to make sure that the address trying to approve the transaction has not already done so
        //We then, set it to true and imcrement the approvals count in the struct
         if(approvals[msg.sender][id] == false){
            approvals[msg.sender][id] = true;
            transfers[id].approvals++;
        }

        //We check if the approvals count is > or = the approval number if not, nothing will be done
        if(transfers[id].approvals >= approvalNum) {
            transfers[id].sent = true; //We change the sent status to true
            address payable to = transfers[id].to; // We get the receipient address from the struct
            uint amount = transfers[id].amount; //we get the amount from the struct
            to.transfer(amount); //we send the eth to the receipient address
            return;
        }
       
    }

    //get the balance of an address
    function balanceOf(address payable _addr) public view returns(uint) {
        return _addr.balance;
    }


    //this enforces that only the approved addresses can use a function
    modifier onlyApprover() {
        bool allowed = false;
        for(uint i = 0; i < approvers.length; i++) {
            if(approvers[i] == msg.sender){ //Checks if the address is one of the approves addresses
                allowed = true;
            }
        }

        require(allowed == true, "Only Approver allowed");
        _;
    }
}