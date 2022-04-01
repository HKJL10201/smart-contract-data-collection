//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Wallet {
    // constants
    uint8 constant public MAX_OWNERS = 255;
    uint8 constant public MAX_TRANSFERS = 255;
    
    // enums
    enum TransferState {
        Deleted, // This state should be only reached when the Transfer item is deleted
        Pending,
        Ready, // Transient state
        Completed,
        Cancelled, // Transient state
        Failed,
        Expired // Transient state
    }
    
    // state variables
    uint public approvalCount;
    uint256 public bitmask = 1; // Can accommodate up to 255 owners
    address[] private owners_array; // Used to cleanup approvals (not worth it in termas of gas)
    mapping(address => uint256) public owners; // Used for onlyOwner modifier
    Transfer[] public transfers; // Infinitely growing
    
    // structs
    struct Transfer {
        uint id;
        address payable recepient;
        uint amount;
        uint creationTime;
        uint approvalCount;
        TransferState state;
        uint256 approvalBitmap;
    }
    
    // events
    event ReportTransferState(
        uint indexed id,
        address indexed recepient,
        uint amount,
        TransferState indexed state
    );
    
    // modifiers
    modifier onlyOwner() {
        require(owners[msg.sender] > 0, "Owner-only operation");
        _;
    }
    
    modifier transferExists(uint _id) {
        require(transfers.length > _id, "Transaction doen't exist");
        _;
    }
    
    // constructor
    constructor(uint _approvalCount, address[] memory _owners) {
        require(_owners.length <= MAX_OWNERS, "Too many owners");
        require(_owners.length >= _approvalCount, "Approval count cannot exceed the number of owners");
        
        // Initialize bitmask and encode owners via the bits
        for(uint i = 0; i < _owners.length; i++) {
            owners_array.push(_owners[i]);
            if (i == 0) {
                owners[_owners[i]] = 1;
            }
            else {
                owners[_owners[i]] = owners[_owners[i-1]] << 1;
                bitmask <<= 1;
                bitmask |= 1;
            }
        }
    }

    //public
    function deposit () public payable  {}
    
    function withdraw (uint amount) public payable onlyOwner {
        payable(msg.sender).transfer(amount);
    }
    
    function getBalance () public view returns (uint) {
        return address(this).balance;
    }
    
    function getOwners() public view returns (uint256[] memory){
        uint256[] memory _addr = new uint256[](owners_array.length);
        for (uint i = 0; i < owners_array.length; i++) {
            _addr[i] = owners[owners_array[i]];
        }
        return _addr;
    }
    
    // Should create a new Transfer object
    // Only owner is allowed to create TransferState
    // Do not create transfers if the wallet balance is lower than the specified amount
    // gas: ?
    function createTransfer (address payable recepient, uint amount) public onlyOwner returns (uint){
        require(address(this).balance >= amount, "Insufficient balance in Wallet");
        
        // Create a new transfer object
        // approvalCount is set to 1 because the creator is assumed to have approved the transfer he has created
        Transfer memory new_transfer = Transfer(
            0,
            recepient,
            amount,
            block.timestamp,
            1, 
            TransferState.Pending,
            bitmask ^ owners[msg.sender]
        );
        
       
        //Register the new transfer
        transfers.push(new_transfer);
        uint index = transfers.length - 1;
        
        processState(index);
        
        return index;
    }
    
    // Approves existing transfers which are in Pending state
    // Only owner can approve transfers
    // Each address can approve transation only once
    // gas: 44471
    function approveTransfer (uint _id) public onlyOwner transferExists(_id) returns (uint){
        require(transfers[_id].state == TransferState.Pending, "Only pending transfer can be approved");
        require(transfers[_id].approvalBitmap & owners[msg.sender] != 0, "This address already approved this transfer");
        
        // Change transfer states
        transfers[_id].approvalCount++;
        transfers[_id].approvalBitmap ^= owners[msg.sender];
        
        assert(
            transfers[_id].approvalCount <= approvalCount &&
            transfers[_id].approvalCount > 1
        );
        
        processState(_id);
        
        return _id;
    }
    
    // Revokes approval from existing transfers which are in Pending state
    // Only owner can revoke transfers
    // Each address can revoke transation only if it has previously approved it
    function revokeTransfer (uint _id) public onlyOwner transferExists(_id) returns (uint){
        require(transfers[_id].state == TransferState.Pending, "Only pending transfer can be revoked");
        require(transfers[_id].approvalBitmap & owners[msg.sender] == 0, "This address didn't approved this transfer");
        
        // Change transfer states
        transfers[_id].approvalCount--;
        transfers[_id].approvalBitmap ^= owners[msg.sender];
        
        assert(
            transfers[_id].approvalCount < approvalCount &&
            transfers[_id].approvalCount >= 0
        );
        
        processState(_id);
        
        return _id;
    }
    
    // Execute transfer that is in Ready state
    function executeTransfer (uint _id) public payable onlyOwner transferExists(_id) returns (uint) {
        require(
            transfers[_id].state == TransferState.Ready ||
            transfers[_id].state == TransferState.Failed,
            "Only Ready or Failed states are allowed"
        );
        
        if (transfers[_id].recepient.send(transfers[_id].amount))
            transfers[_id].state = TransferState.Completed;
        else
            transfers[_id].state = TransferState.Failed;
        
        processState(_id);
        
        return _id;
    }
    
    // Cancels transfer that is in Failed state
    function cancelFailedTransfer (uint _id) public onlyOwner transferExists(_id) returns (uint) {
        require(transfers[_id].state == TransferState.Failed, "Only Failed transfer can be cancelled");
        
        transfers[_id].state == TransferState.Cancelled;
        
        processState(_id);
        
        return _id;
    }
    

    //private
    function processState(uint _id) private {
        Transfer storage t = transfers[_id];
        
        if (t.state == TransferState.Pending) {
            // emit event only if the transfer has just been created
            if (t.approvalCount == 1)
                emit ReportTransferState(_id, t.recepient, t.amount, t.state);
            
            if (t.approvalCount == approvalCount)
                t.state = TransferState.Ready;
            else if (t.approvalCount == 0)
                t.state = TransferState.Cancelled;
        }
        
        if (t.state == TransferState.Ready) {
            executeTransfer(_id);
        }
        
        if (t.state == TransferState.Failed) {
            emit ReportTransferState(_id, t.recepient, t.amount, t.state);
        }
        
        if (t.state == TransferState.Cancelled || t.state == TransferState.Completed) {
            emit ReportTransferState(_id, t.recepient, t.amount, t.state);
            
            // with deletion: 39259 for the final approval
            // w/o deletion: 54601 for the final approval
            delete transfers[_id]; 
        }
    }
}
