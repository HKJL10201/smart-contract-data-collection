pragma solidity 0.7.5;
pragma abicoder v2;

import "./Ownable.sol";

contract Wallet is Ownable{
    //variables
    address[] public owners;
    uint sigsNeeded;
    uint balance;
    
    //structs
    struct Transfer{
        uint transferID;
        address payable recipient;
        uint amount;
        uint noOfApprovals;
        bool hasBeenSent;
    }
    
    //mappings
    mapping(address => mapping(uint=>bool)) approvals; //a double mapping - remember it's similar to a dictionary!
   
    //events    
    event depositDone(uint amount, address indexed depositedTo);
    event TransferRequestMade(uint amount, address indexed sentTo, uint transferID);
    event ApprovalReceived(uint _transferID, uint _approvals, address _approver);
    event TransferApproved(uint _transferID);
    
    //modifier
    modifier onlyOwners(){ // only allow people in the owners list to execute 
        bool owner = false;
        for(uint i=0; i<owners.length; i++){
            if(owners[i] == msg.sender){
                owner=true;
            }
        }
        require (owner==true, "Sender not an owner"); //if it's not true will throw an error
        _;
    }
    
    //constructor
    constructor (address[] memory _owners, uint _sigsNeeded) { //gets run only the first time the contract gets run i.e. at 'setup'
       owners = _owners;
       sigsNeeded = _sigsNeeded;
    }

    Transfer[] transferRequests; //create a instance of a struct to hold the transfer requests
  
    function deposit () public payable returns (uint) { //this allows anyone to deposit - this could be an empty function!
       balance += msg.value;
       emit depositDone(msg.value, msg.sender);
       return balance;
    }
       
    function transfer (address payable _recipient, uint _amount) public onlyOwners{
       require(balance >= _amount, "Balance not sufficient"); // if not the case, revert happens, transaction will not happen
       
       transferRequests.push(
           Transfer(transferRequests.length, _recipient, _amount, 0, false) // add this latest transfer request to the transferRequests array
           );
       
       emit TransferRequestMade(_amount, _recipient, transferRequests.length-1); //emit that a transfer request has been made
       balance -= _amount; //decrease balance by the amount of the request - should this be done here? or only later when the transfer is actually made?
    }
    
    function approve (uint _transferID) public payable onlyOwners {
        require(approvals[msg.sender][_transferID] == false); //check that this person hasn't approved this transaction already
        require(transferRequests[_transferID].hasBeenSent == false);
        
        approvals[msg.sender][_transferID] == true; //set that this person has now approved this transaction (can't do it again)
        transferRequests[_transferID].noOfApprovals++; //increase number of approvals by 1
        emit ApprovalReceived(_transferID, transferRequests[_transferID].noOfApprovals, msg.sender);
        
        if (transferRequests[_transferID].noOfApprovals >= sigsNeeded) { //check if enough approvals
            transferRequests[_transferID].hasBeenSent = true;
            address payable payableRecipient = transferRequests[_transferID].recipient; //make the address payable
            payableRecipient.transfer(transferRequests[_transferID].amount); //makes the transfer
            emit TransferApproved(_transferID);
        }
    }
   
    function getBalance() public view returns (uint) {
       return balance; 
    }
    
    function getTransferRequests() public view returns (Transfer[] memory){
        return transferRequests;
    }

}
