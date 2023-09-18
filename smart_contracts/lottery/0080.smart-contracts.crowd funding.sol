//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;

contract crowdFunding{
   mapping(address=>uint) public contributers;     //contributers[msg.sender] represents ether they have sent
   address public manager;
   uint public deadline;
   uint public raisedMoney;
   uint public target;
   uint public noOfContibuters;

   struct Request{
       string description;
       uint value;
       address payable recipient; //the person for which the request is generated
       bool completed; 
       uint noOfVoters;  
       mapping(address=>bool) voters;    
       
   }

   mapping(uint=>Request) public requests;
   uint public numRequests;


   constructor (uint _deadline, uint _target){
       manager=msg.sender;
       deadline= block.timestamp+ _deadline;  //10sec+3600sec
       target= _target;
       

   }

   function contributeEther() payable public{
       require(msg.value>=1 ether,"Minimum contribution is 1 ether");
       require(block.timestamp<deadline,"Deadline crossed");

       if(contributers[msg.sender]==0)
       {
           noOfContibuters++;
       }

       contributers[msg.sender]=contributers[msg.sender] + msg.value;    //for contributing more than once
        raisedMoney=raisedMoney+contributers[msg.sender];
   }

    function checkBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp>deadline && raisedMoney<target,"Cannot refund");
        require(contributers[msg.sender]>0,"Cannot refund as you didn't contribute");   //to avoid 2nd time refund for the same contributor
        address payable user=payable(msg.sender);
        user.transfer(contributers[msg.sender]);
        contributers[msg.sender]=0;
        
    }
     modifier onlyManger(){     //lets us escape writing require again n again in every function
        require(msg.sender==manager,"Only manager can call this function");
        _;
    }


    function createRequests(string memory _description,uint _value, address payable _recipient) public onlyManger {
           Request storage newRequest= requests[numRequests];
           numRequests++;
           newRequest.description=_description;
           newRequest.value=_value;
           newRequest.recipient=_recipient;
           newRequest.completed=false;
           newRequest.noOfVoters=0;
    }

    function voteRequest(uint _requestNo) public{
        require(contributers[msg.sender]>0,"You are not a contributor");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
        
    }

    function makePayment(uint _requestNo) public onlyManger{
        require(raisedMoney>=target,"Target not reached");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false,"The request has been completed");
        require(thisRequest.noOfVoters>noOfContibuters/2,"Majority doesnot support");    //if a requests get more than 50% votes then its a majority
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
        
    }
}