// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/*
    * To-do list *
        * Refactor the current approach to store the approvers of the multi-sig wallet!
            - Find a way to avoid the need to iterate over an array to validate if the caller belongs to the approvers!
                * Good idea: https://ethereum.stackexchange.com/questions/56281/how-to-check-if-an-array-key-exists *
*/

contract MultiSigWallet {
    address[] public approvers; 
    uint public quorum;
    address manager;

    struct Transfer {
        uint transferId;
        address payable to;
        uint amount;
        uint approvals;
        bool sent;
    }

    Transfer[] transfers; // array to store all the Transfer instances that will be created!

    mapping(address => mapping(uint => bool)) approved; // nested mapping to keep track of the Transfers that the users have already approved! | the uint key of the second mapping represents the tranferId


    constructor(address[] memory _approvers)  {
        approvers = _approvers;
        quorum = approvers.length;  // All the approvers are required to approve a transaction
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Onlt the manager can call this function");
        _;
    }

    modifier onlyApprovers() {
        bool allowed = false;

        // Look in the approvers[] array if the caller(msg.sender) exists!
        for(uint i = 0; i < approvers.length; i++) {
            if(msg.sender == approvers[i]) {
                allowed = true;
                break;
            }
        }
        
        // if the caller was found in the approvers[], the allowed variables will be set to true!
        require(allowed == true, "Only approvers can call this function");
        _;
    }

    function addApprover(address newApprover) external onlyManager() {
        approvers.push(newApprover);
        quorum++;
        require(quorum == approvers.length, "Something went wrong while adding the new approver, reverting the transaction");
    }

    function getApprovers() external view returns(address[] memory) {
        return approvers;
    }

    function getTransfers() external view returns(Transfer[] memory) {
        return transfers;
    }

    function createTransfer(uint _amount, address payable _to) external onlyApprovers() {
        transfers.push(Transfer(transfers.length, _to, _amount,0,false));
    }

    function approveTransfer(uint _transferId) external onlyApprovers() {
        require(transfers[_transferId].sent == false, "This transfer has already been sent");
        require(approved[msg.sender][_transferId] == false, "The same user can't approve the transfer twice");

        // Register that this caller has already approved this transaction
        approved[msg.sender][_transferId] = true;

        // If above validations are successfully meet, proceed to approve the transaction!
        transfers[_transferId].approvals++;

        // Check if the transaction has enough approvals
        if (transfers[_transferId].approvals == quorum){
            // Update the sent variable to true before sending the Ethers
            transfers[_transferId].sent = true; 

            address payable to = transfers[_transferId].to;
            uint amount = transfers[_transferId].amount;
            // Send the amount of Ethers to the receiver using the call{}("") method!
            (bool success, ) = to.call{ value: amount }("");    // Remember, amount is in wei units!
            require(success, "Something went wrong while transfering the Ethers, reverting the transaction, please try again");
        }     
    }

    // function to receive Ethers
    receive() external payable {}


}