pragma solidity ^0.4.24;

contract myWallet {
    
    address owner = msg.sender;
    
    //use the modifier to call onlyOwner as a msg.sender
    modifier onlyOwner () {
        if(owner == msg.sender){
            _;
        } else {
            throw;
        }
    }
    
    //mapping the address to the permission struct which is declared later on below
    mapping(address => Permission) permittedAddress;
    
    event someoneAddedSomeoneToTheSenderList();
    
    struct Permission{
        bool isAllowed;
        uint maxTransferAmount;
    }
    
    function addAddressToSenderLists(address permitted, uint maxTransferAmount) onlyOwner{
        permittedAddress[permitted] = Permission(true, maxTransferAmount);
    }
    
    //if the owner is allowed and he has less eth to send than the maxTransferAmount
    function sendFunds (address receiver, uint amountInWei) onlyOwner{
        if(permittedAddress[msg.sender].isAllowed) {
            if(permittedAddress[msg.sender].maxTransferAmount >= amountInWei) {
                receiver.send(amountInWei);
            }
        }
    }
    
    //delete the address from senders list
    function removeAddressFromSendersList(address theAddress) onlyOwner{
        delete permittedAddress[theAddress];
    }
    
            //return the contract balance
    function getMyContractBalance () constant returns (uint) {
        address myAddress = this;
        return myAddress.balance;
    }
    
    function addMoneyInYourSmartContract() payable {
    }
}