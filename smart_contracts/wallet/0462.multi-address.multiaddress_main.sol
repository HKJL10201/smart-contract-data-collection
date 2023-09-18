pragma solidity ^0.8.7;

import "./multiaddress_top.sol";

contract MultiAddress is Base{
    
    Business[] mybusiness;
    Transaction[] transactions;
    mapping(address => uint[]) listOfTransaction;
    mapping(uint => address[]) listOfApprovals;
    
    // function to create a business in which parterns will be there for transaction approval
    function addBusiness(string memory _bname) public onlyOwner returns(bool, uint){
        uint prevLen = mybusiness.length;
        Business memory _temp;
        _temp.BID = prevLen;
        _temp.businessName = _bname;
        mybusiness.push(_temp);
        return(mybusiness.length == prevLen+1, mybusiness.length);
    }
    
    //function to add a partner to a business
    function addPartnerToBusiness(uint _BID, address _partner) public onlyOwner returns(bool){
        uint partnerLength = mybusiness[_BID].partners.length;
        mybusiness[_BID].partners.push(_partner);
        return mybusiness[_BID].partners.length == partnerLength+1;
    }
    
    //function to initiate the transaction, only the owner can do so however it may be changed to other requirements such as if partners need to initiate transaction
    function initiateTransaction(uint _BID, address _receiver) public onlyOwner payable returns(Transaction memory) {
        uint _TID = transactions.length;
        uint _approvalRequired = mybusiness[_BID].partners.length;
        address _sender = msg.sender;
        uint _amount = msg.value;
        string memory _status = "Pending";
        Transaction memory _tempTransaction = Transaction(_TID,0,_approvalRequired,_sender,_receiver,_amount,_status);
        transactions.push(_tempTransaction);
        _sendForApproval(_BID,_TID); // all the partner addresses will be added as approval list 
        _checkForApproval(_TID); // if there are no partners i.e. only the onwer then it will be auto approved and sent
        return _tempTransaction;
    }
    
    // this function is used by a partner address to approve a transaction 
    function approveTransaction(uint _TID)public notOwner{
        require(_checkForUser(_TID),"User either not present or have already approved!");
        transactions[_TID].approvalGot++;
        _checkForApproval(_TID);
    }
    
    //function to get a transaction corresponding to a transaction ID
    function getTransactionFromId(uint _TID)public view returns(Transaction memory){
        //Transaction memory _temp = transactions[_TID];
        return transactions[_TID];
    }
    
    //function to get the value of the contract
    function getValueOfContract() public view returns(uint){
        return address(this).balance;
    }
    
    //after the transaction has been approved from all the partners then this function is used to send the value to the receiver
    //this function is followed by another function called _checkForApproval
    function sendValue(uint _TID) internal {
        address payable receiver = payable(transactions[_TID].receiver);
        uint amount = transactions[_TID].amount;
        receiver.transfer(amount);
        transactions[_TID].status = "Completed";
    }
    
    //this function will map the transaction ID to all the partner addresses 
    function _sendForApproval(uint _BID, uint _TID) private {
        uint len = mybusiness[_BID].partners.length;
        for(uint i=0; i<len; i++){
            address _user = mybusiness[_BID].partners[i];
            listOfTransaction[_user].push(_TID);
        }
    }
    
    //this function is used to check whether an address is the partner address for the given transaction or not
    function _searchForUser(uint _TID, address _user) private view returns(bool){
        uint[] memory users = listOfTransaction[_user];
        for(uint i=0; i<users.length; i++){
            if(users[i] == _TID) return true;
        }
        return false;
    }
    
    //this function is used to check whether a partner address have already approved for a transaction or not
    function _searchForApproval(uint _TID, address _user) private view returns(bool){
        address[] memory addresses = listOfApprovals[_TID];
        for(uint i=0; i<addresses.length; i++){
            if(addresses[i] == _user) return true;
        }
        return false;
    }
    
    //this function combines both the above boolean functions and returns if the above two conditions are satisfied or not
    function _checkForUser(uint _TID) private view returns(bool){
        address _user = msg.sender;
        bool _userPresent = _searchForUser(_TID,_user);
        bool _userVoted = _searchForApproval(_TID,_user);
        return _userPresent&&!_userVoted;
    }
    
    //this function is used to check if a transaction has gathered all the approvals or not 
    function _checkForApproval(uint _TID)private {
        if(transactions[_TID].approvalGot == transactions[_TID].approvalRequired){
            sendValue(_TID);
        }
    }
    
    //     //below are the functions used  for debugging
//     function getAPartner(uint _BID) public view returns(address){
//         return mybusiness[_BID].partners[mybusiness[_BID].partners.length-1];
//     }
    
//     function getTransactionList() public view returns(uint[] memory){
//         return listOfTransaction[msg.sender];
//     }
    
//     function getApprovalList(uint _TID) public view returns(address[] memory){
//         return listOfApprovals[_TID];
//     }
    
}
