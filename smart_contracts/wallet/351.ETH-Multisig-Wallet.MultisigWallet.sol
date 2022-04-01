// SPDX-License-Identifier: MIT
pragma abicoder v2;
pragma solidity ^0.7.5;

/* 

    Multisig Wallet Smart Contract Project : 
    
    - A Multisig wallet will hold Ether and in order to spend or send money out from 
      the wallet you need to have approval of a certain amount of signatures for the 
      transaction to be approved (2/3 or a 3 person multisig wallet)
    
        - Requires at least 2 parties to sign for valid transfer
        - Anyone can deposit funds into smart contract
        - Spendng funds requires at least 2 sigs
        - The contract creator should be able to input 
            - (1): the addresses of the owners and 
            - (2): the numbers of approvals required for a transfer, in the constructor. 
            - For example, input 3 addresses and set the approval limit to 2. 

       - Anyone of the owners should be able to create a transfer request. 
         The creator of the transfer request will specify what amount and to 
         what address the transfer will be made
         
       - Owners should be able to approve transfer requests.     
       
       - When a transfer request has the required approvals, the transfer should be sent. 
*/

// Store owners of wallet >> address []
// Specify how many signatures needed for valid tx >> uint limit

contract MultisigWallet {
    address[] public owners;
    uint256 limit;

    // struct for tranfer/ requests
    struct Transfer {
        uint256 amount;
        address payable receiver;
        uint256 approvals;
        bool hasBeenSent;
        uint256 id;
    }

    event TransferRequestCreated(
        uint256 _id,
        uint256 _amount,
        address _initiator,
        address _receiver
    );
    event ApprovalReceived(uint256 _id, uint256 _approvals, address _approver);
    event TransferApproved(uint256 _id);
    // array of objects to store transfer requests
    Transfer[] transferRequests;

    // store approvals >> specific for one transfer request >> double mapping

    mapping(address => mapping(uint256 => bool)) approvals;

    // Should only allow people in the owners list to continue the execution.
    modifier onlyOwners() {
        bool owner = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                owner = true;
            }
        }
        require(owner == true);
        _;
    }

    // Should initialize the owners list and the limit
    constructor(address[] memory _owners, uint256 _limit) {
        owners = _owners;
        limit = _limit;
    }

    // Empty function
    function deposit() public payable {}

    // Create an instance of the Transfer struct and add it to the transferRequests array
    function createTransfer(uint256 _amount, address payable _receiver)
        public
        onlyOwners
    {
        emit TransferRequestCreated(
            transferRequests.length,
            _amount,
            msg.sender,
            _receiver
        );
        transferRequests.push(
            Transfer(_amount, _receiver, 0, false, transferRequests.length)
            // add event that transfer has been created to alert owners
        );
    }

    /*
    - Set approval for one of the transfer requests
    - Need to update the Transfer object
    - Need to update the mapping to record the approval for the msg.sender
    - When the amount of approvals for a transfer has reached the limit, 
      this function should send the transfer to the recipient
    - An owner should not be able to vote 2x
    - An owner should not be able to vote on a transfer request that has already been sent
*/

    function approve(uint256 _id) public onlyOwners {
        require(approvals[msg.sender][_id] == false);
        require(transferRequests[_id].hasBeenSent == false);

        approvals[msg.sender][_id] = true;
        transferRequests[_id].approvals++;

        emit ApprovalReceived(_id, transferRequests[_id].approvals, msg.sender);

        if (transferRequests[_id].approvals >= limit) {
            transferRequests[_id].hasBeenSent = true;
            transferRequests[_id].receiver.transfer(
                transferRequests[_id].amount
                emit TransferApproved(_id);
            );
        }
    }

    // Should return all transfer requests
    function getTransferRequests() public view returns (Transfer[] memory) {
        return transferRequests;
    }
}


