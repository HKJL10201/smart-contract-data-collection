// SPDX-License-Identifier: GPL-3.0
 
 
// Contributors
// Manager
// minContribution
//deadline
//target
//raiseAmount
//noOfContributors
 
pragma solidity >=0.4.0 <0.9.0;
 
contract CrowdFunding{
   mapping (address => uint) public Contributors;
   address public Manager;
   uint public minContribution;
   uint public deadline;
   uint public target;
   uint public raiseAmount;
   uint public noOfContributors;
  
   struct Request{
       string description;
       address payable recipient;
       uint value;
       bool isCompleted;
       uint noOfVoters;
       mapping (address=>bool) voters;
      
   }
  
   mapping (uint=>Request) public requests;
   uint public numRequests;
  
   constructor(uint _target , uint _deadline){
       target = _target;
       deadline = block.timestamp + _deadline;// block timestamp gives the time in seconds from the creation of first block
       minContribution =100 wei;
       Manager = msg.sender;
      
   }
  
  
   function sendEth() public payable{
       require(block.timestamp < deadline ,"deadline has been passed");
       require(msg.value >= 100 wei , "Minimum Contribution is not met") ;
      
       if(Contributors[msg.sender] ==0){
           noOfContributors++;
       }
      
       Contributors[msg.sender] += msg.value;
       raiseAmount += msg.value;
   }
  
   function getContractBalance() public view returns(uint){
       return address(this).balance;
   }
  
  
   function refund() public {
       require(block.timestamp > deadline && raiseAmount < target , "you are not eligble to refund");
       require(Contributors[msg.sender]>0,"Contributor not contributed");//person who initiated refund must be a contributor
       address payable user = payable(msg.sender);// converting msg.sender to payable
       user.transfer(Contributors[msg.sender]);// transfer the amount to contributer who initiated the refund
       Contributors[msg.sender] = 0;
      
       }
      
       modifier onlyMnager(){
           require(msg.sender == Manager," Only manager can call the function");
            _;  
       }
      
      
       function createRequest(string memory _description , address payable _recipient , uint _value) public onlyMnager{
           Request storage newRequest = requests[numRequests];
           numRequests++;
           newRequest.description = _description;
           newRequest.recipient=_recipient;
           newRequest.value=_value;
           newRequest.isCompleted=false;
           newRequest.noOfVoters=0;
          
       }
      
       function VoteRequest(uint _requestNo ) public  {
           require(Contributors[msg.sender]>0,"you are not a contributor");
           Request storage thisRequest=requests[_requestNo];
           require(thisRequest.voters[msg.sender]==false ," you have already voted");
           thisRequest.voters[msg.sender]=true;
           thisRequest.noOfVoters++;
       }
      
       function makePayment(uint _requestNo) public onlyMnager{
           require(raiseAmount >= target);
           Request storage thisRequest=requests[_requestNo];
           require(thisRequest.isCompleted==false ,"Amount dirtibuted already ");
           require(thisRequest.noOfVoters > noOfContributors/2 , "Majority should be support ie 50%");
           thisRequest.recipient.transfer(thisRequest.value);
           thisRequest.isCompleted=true;
          
          
       }
  
}
 
 
 