//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;

contract CrowdFunding{
    //defining the mapping to get contributors
    //linking addresses to contributors
    mapping(address=>uint) public contributors;

    address public manager;

    uint public minimumContribution;

    uint public deadline;

    uint public target;

    uint public raisedAmount;

    uint public noOfContributors;

    //making a structure for request
    struct Request {
        string description; //why the money is needed
        address payable recipient; //for whom the money is needed 
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests; //Here we are mapping the number of requests
    uint public numRequests;

    //defining a constructor(first function which runs after deployement) in which _target, _deadline are already set by the manager
    constructor(uint _target, uint _deadline){
        target=_target;
        deadline= block.timestamp + _deadline;
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    //creating a function for contributors to send eth
    function sendEth() public payable{
        require(block.timestamp < deadline, "Deadline exceeded.");
        //checking whether the value being given is greater than our specified minimumcontribution
        require(msg.value >= minimumContribution, "Minimum contribution not met.");

        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    //checking balance after receiving money 
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp > deadline && raisedAmount < target);
        require(contributors[msg.sender] > 0);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    modifier onlyManager(){
        require(msg.sender == manager, "Manager has access.");
        _;
    }

    function createRequests(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    //function for voting
    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0, "You must be a contributor to vote!"); //checking whether a contributor or not
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] == false, "You have already voted."); //checking if person has already voted or not.
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;

    }

    function makePayment(uint _requestNo) public onlyManager {
        require(raisedAmount>=target); //checking whether raised amount is greater than the target.
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed==false, "Payment already successful.");
        require(thisRequest.noOfVoters > noOfContributors/2, "Majority not in favour.");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}