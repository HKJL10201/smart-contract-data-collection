pragma solidity 0.7.5;
pragma abicoder v2;

contract MultisigWallet{
    
    address[] public owners; 
    uint limitNumberToApprove;
  
    struct Transfer {
        address payable to;
        uint approvals;
        uint amount;
        uint txid;
        bool isSent;
    }
    
    Transfer[] pendingTransfers;
    
    mapping (address => mapping(uint => bool)) approvals;
    
    //Allows only the multisig wallet owners to run a function 
    modifier onlyOwners {
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
    
    event TransferCreated(uint _id, uint _amount, address _initiator, address _receiver);
    event ApprovalReceived(uint _id, uint _approvals, address _approver);
    event TransferApproved(uint _id);

    constructor(address[] memory _owners, uint _limitNumberToApprove) {
        require (_owners.length >= _limitNumberToApprove, "Owners must be more than required approvals number");
        
        owners = _owners;
        limitNumberToApprove = _limitNumberToApprove;
    }
    
    //Only accepts deposit inside the contract
    function deposit() public payable {}
    

    function createTransfer(address payable _to, uint _amount) public onlyOwners {
        require (_amount <= address(this).balance, "Not enough funds in the Multisig wallet ");
        
        uint id = pendingTransfers.length;
        emit TransferCreated(id, _amount, msg.sender, _to);
        pendingTransfers.push(Transfer(_to, 0, _amount, id, false));
    }
    
    
    function approveTransfer(uint _id) public onlyOwners returns(bool){
        require(!approvals[msg.sender][_id]);                       //An owner can't approve twice
        require(_id < pendingTransfers.length, "Invalid index");    //The id must be in the range of the pendingTransfers size 
        require(!pendingTransfers[_id].isSent);                     //An owner can't approve a tx already sent
        
       
        approvals[msg.sender][_id] = true;          //Record that that owner has already approved this transfer
        
        pendingTransfers[_id].approvals++;          //Increment approvals of the Transfer object
        
        emit ApprovalReceived(_id, pendingTransfers[_id].approvals, msg.sender);
      
        if (pendingTransfers[_id].approvals >= limitNumberToApprove) {
            executeTransfer(_id);
            return true;
        }
        
        return false;
    }
    
    function executeTransfer(uint _id) private {
        require(address(this).balance >= pendingTransfers[_id].amount, "Balance not sufficient");
        
        (pendingTransfers[_id].to).transfer(pendingTransfers[_id].amount);
        
        pendingTransfers[_id].isSent = true;  //Update the state of the tx, meaning it has been sent

         emit TransferApproved(_id);
    }
    
    //For debugging
    function getPendingTransfer() public view returns (Transfer[] memory){
        return pendingTransfers;
    }
    
}