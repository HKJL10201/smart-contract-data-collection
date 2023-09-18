//SPDX-License-Identifier: MIT
// Renzo Barrios
// Octuber 2021
pragma solidity ^0.8.0;


import "hardhat/console.sol";

contract Wallet {

    address[] public approvers;
    uint256 public quorum;

    struct Transfer { 
        uint id;
        uint amount;
        address payable to ;
        uint approvals;
        bool sent;
    }

    Transfer[] public transfers;
    mapping(address => mapping(uint => bool)) public approvals;

    constructor(address[] memory _approvers, uint256  _quorum) payable{
        approvers = _approvers;
        quorum = _quorum;
    }


    // only approvers specified in the constructor can call createTransfer
    function createTransfer(
        uint _amount,
        address payable _to
        ) external onlyApprover() payable returns(Transfer memory) {
            

        Transfer memory newTransfer = Transfer({
         id: transfers.length,
         amount:_amount,
         to: _to,
         approvals:0,
         sent:false
        });

        transfers.push(newTransfer);


        return newTransfer;
    }


    function approveTransfer(uint id) external onlyApprover() {
        require(transfers[id].sent == false,"Transfer already been sent");
        require(approvals[msg.sender][id] == false, "Cannot approve transfers twice");

        approvals[msg.sender][id] = true;
        transfers[id].approvals++;

        if( transfers[id].approvals >= quorum ){
                transfers[id].sent = true;
                uint amount = transfers[id].amount;
                address payable to = transfers[id].to;
                to.transfer(amount);
        }
    }


    // getters
    function getApprovers() external view returns (address[] memory){
        return approvers;
    }

    function getTransfers() external view returns (Transfer[] memory){
        return transfers;
    }

    // receive ether native way
    receive() external payable {}

    modifier onlyApprover(){
        bool allowed = false;

        for(uint i = 0; i < approvers.length; i++){
            if(approvers[i] == msg.sender) {
                allowed = true;
            }
        }

        require(allowed == true, "only approver allowed");
        _;
    }

    

}
