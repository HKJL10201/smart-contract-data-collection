// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 < 0.9.0;

contract crowdFunding {
    address public manager;
    uint public target;
    uint public deadline;
    uint public minContribution;
    uint public raisedAmount; //how much has been currently raised
    uint public noOfContributors; //to check consensus
    mapping (address=>uint) public contributors;

    struct Request{
        string description;
        address payable recipient; //who needs the money?
        uint value;
        bool completed; // is the request pending?
        uint noOfVoters; //how many contributors voted for request
        mapping(address=>bool) voters; //which address said yes/no during consensus
    }

    mapping(uint=>Request) public requests; // mapping of all the requests with index number
    uint public numRequests;

    constructor (uint _target, uint _deadline) public {
        target = _target;
        deadline = block.timestamp + _deadline; //here _deadline should be in seconds
        minContribution = 100 wei;
        manager = msg.sender;
    }

    function sendEther() public payable {
        require(block.timestamp>deadline, "Deadline has passed"); //to make sure that deadline hasn't crossed
        require(msg.value >= minContribution, "Minimum contribution is not met"); //atleast minimum contribution should be made
        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function checkbalance() public view returns(uint) {
        return address(this).balance;
    }

    function refund() public {
        require(raisedAmount<target && block.timestamp>deadline, "You are not eligible for refund");
        require(contributors[msg.sender]>0);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    modifier onlyManager(){
        require(msg.sender == manager, "Only manager can call this function."); //we can use this modifier in functions that only manager can call
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _requestNo) public {
        require(contributors[msg.sender]>0, "You need to be a contributor ");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] = false, "You have already voted.");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public {
        require(raisedAmount>=target, "Enough money has not been raised yet.");
        Request storage thisrequest = requests[_requestNo];
        require(thisrequest.completed == false, "the request is already complete");
        require(thisrequest.noOfVoters>noOfContributors/2, "There is no majority to go ahead with the decision");
        thisrequest.recipient.transfer(thisrequest.value);
        thisrequest.completed = true;
    }
}