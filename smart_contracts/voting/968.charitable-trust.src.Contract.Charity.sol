//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;

contract Contract{
    mapping(address=>uint) public contributors; //contributors[msg.sender]=100
    address public manager; 
    uint public minimumContribution;
    uint public raisedAmount;
    uint public noOfContributors;
    struct Request{
        uint uniqueid;
        string description;
        address payable recipient;
        uint target;
        bool completed;
        uint noOfVoters;
        address[] voters;
    }
    receive() external payable {}
    mapping(uint=>Request) public requests;
    uint public numRequests;
    constructor() public{
        minimumContribution=100 wei;
        manager=msg.sender;
    }
    function sendEth() public payable{
        require(msg.value >=minimumContribution,"Minimum Contribution is not met");
        
        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    function createRequests(string memory _description,address payable _recipient,uint _target) public {
        require(msg.sender==manager,"Only manager can calll this function");
        Request storage newRequest = requests[numRequests];
        newRequest.uniqueid=numRequests;
        newRequest.description=_description;
        newRequest.recipient=payable(_recipient);
        newRequest.target=_target;
        newRequest.completed=false;
        newRequest.noOfVoters=0;
        numRequests++;
    }
    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0,"YOu must be contributor");
        Request storage thisRequest=requests[_requestNo];
        address[] memory arry = thisRequest.voters;
        for (uint i = 0; i < arry.length; i++) {
        require(arry[i]!=msg.sender,"You already Voted");
        }
        thisRequest.noOfVoters+=1;
        thisRequest.voters.push(msg.sender);
    }
    function makePayment(uint _requestNo) public  {
        require(msg.sender==manager,"Only manager can calll this function");
        Request storage thisRequest=requests[_requestNo];
        require(raisedAmount>=thisRequest.target);
        require(thisRequest.completed==false,"The request has been completed");
        require(thisRequest.noOfVoters > noOfContributors/2,"Majority does not support");
        thisRequest.recipient.transfer(thisRequest.target);
        thisRequest.completed=true;
    }
}
//contractAddress = 