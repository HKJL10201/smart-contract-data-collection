// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;


contract Wallet {
  
	address[] public approvers;
	uint public quorum;

	// Data Structure for the transfer
	struct Transfer {
		uint id;
		uint amount;
		address payable to;
		uint approvals; // Number of approvals 
		bool sent; // Did we send transfer
	}

	// Create arrary to store Transfer data structure
	//Trasnsfer[] public transfers;
    Transfer[] transfers;


	// Create mapping to track who has approved what Transfer
	// Tracks if the selected address has approved the selected Transfer
	mapping(address => mapping(uint => bool)) public approvals;


	constructor(address[] memory _approvers, uint _quorum) public{

		// Initialize variables
		approvers = _approvers;
		quorum = _quorum;
	}


	// Get a list of all the approvers
	function getApprovers() external view returns(address[] memory){

		return approvers;
	}

	// Get a list of all the Transfers in the mapping object
	// Transfer[]: To use this we must add 'pragma experimental ABIEncoderV2'
	function getTransfers() external view returns(Transfer[] memory){

		return transfers;
	}

	// Create a new Transfer data structure and story in an array
	function createTransfer(uint _amount, address payable _to) external onlyApprover() {

		// Populate array with next Transfer data structure
		transfers.push(
			Transfer(
				transfers.length,
				_amount,
				_to,
				0,
				false
			)
		);
	}

	// Populate approvals array with the address that called this function
	// If we have enough approavals then send transfer if not already sent
	// If function must be called by each of the address that are required
	// for the multisig approval
	function approveTransfer(uint _id) external onlyApprover() {

		// Check to see if the Transfer has already been approved and sent
		require(transfers[_id].sent == false, 'transfer has already been sent');

		// Check to see if this address has not already approved this transfer
		require(approvals[msg.sender][_id] == false, 'cannot approve transfer twice');

		// Set the approavl to true so they cannot set it again
		approvals[msg.sender][_id] = true;

		// Increment the number of approvals for this Transfer data structure
		transfers[_id].approvals++;

		// Validate we have enough approvals to perform transfer
		// If we reach quorum then send transfer
		if(transfers[_id].approvals >= quorum){

			// Setup variables for built-in transfer
			transfers[_id].sent = true;
			address payable to = transfers[_id].to;
			uint amount = transfers[_id].amount;

			// Send transfer
			// transfer: built-in solidity method available to all address payable variables
			// Use the new call function 
			to.transfer(amount);
		}
	}

	// Send some ether to the smart contract.
	// You don't have to call a specific function.
	// Just send ether from an address to the address of the Smart Contract.
	// Old Way: //function sendEther() external payable{}
	receive() external payable{}
	
	// Only allow approvers to execute a function
    modifier onlyApprover(){

        bool allowed = false;

        // Iterate through the approvers array and see if the address calling this function is in that array
        for(uint i = 0; i < approvers.length; i++){

            if (approvers[i] == msg.sender){

                allowed = true;
                //break; Can optimize code and add a break to exit out of loop
            }
        }

        require(allowed == true, 'only approver allowed');
        _;
    }

}	