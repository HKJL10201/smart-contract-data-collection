//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;



contract Multisig {
    //declaring variable of owners
    address[] public owners;
    //declaring a variable 'limitNumberToApprove' to check the number of approvals needed for a transaction
    uint limitNumberToApprove;

    //create a struct 'Transfer' 
    struct Transfer{
        address payable to;
        uint approvals;
        uint amount;
        uint txid;
        bool sent;
    }

    //create an array of Transfer with variable name 'pendingTransfer'
    Transfer[] pendingTransfer;

    mapping (address => mapping(uint => bool)) approvals;


    //create a modifier called onlyOwner to restrict calling of some functions
    modifier onlyOwner {
        bool isOwner = false;
        for (uint i = 0; i < owners.length; i++){
            if (owners[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "You're not an owner");
        _;
    }

    event TransferCreated(uint _id, uint amount, address _initiator, address _receiver);
    event ApprovalReceived(uint _id, uint _approvals, address approver);
    event TransferApproved(uint _id);

    constructor(address[] memory _owners, uint _limitNumberToApprove){
        require(_owners.length >= limitNumberToApprove, "The Owners Must Be More Than Or Equal To The Nunmbers Of Approval");
        owners = _owners;
        limitNumberToApprove = _limitNumberToApprove;
    }

    function addDeposit() public payable {}

    function createTransfer(address payable _to, uint _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Don't have sufficient balance in your multisig wallet");
        uint id = pendingTransfer.length; 
        emit TransferCreated(id, _amount, msg.sender, _to);
        pendingTransfer.push(Transfer(_to, 0, _amount, id, false));
    }

    function approveTransfer(uint _id) public onlyOwner returns (bool){
        require(!approvals[msg.sender][_id]);
        require(_id < pendingTransfer.length, "The Index is invalid");
        require(!pendingTransfer[_id].sent);

        approvals[msg.sender][_id] = true;
        pendingTransfer[_id].approvals++;

        emit ApprovalReceived(_id, pendingTransfer[_id].approvals, msg.sender);

        if(pendingTransfer[_id].approvals >= limitNumberToApprove){
            executeTransfer(_id);
            return true;
        }
    }

    function executeTransfer(uint _id) private {
        require(address(this).balance >= pendingTransfer[_id].amount, "Insufficient Balance");
        (pendingTransfer[_id].to).transfer(pendingTransfer[_id].amount);
        
        pendingTransfer[_id].sent = true;  //Update the state of the tx, meaning it has been sent

         emit TransferApproved(_id);
    }

    function getPendingTransfer() public view returns (Transfer[] memory){
        return pendingTransfer;
    }
}