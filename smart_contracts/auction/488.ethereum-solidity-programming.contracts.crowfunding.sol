//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

contract CrowFunding{
    mapping(address => uint) public contributors;
    address public admin;
    uint public noOfContributors;
    uint public minimumContribution;
    uint public deadline; // timestamp
    uint public goal;
    uint public raisedAmount;
    
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping (address => bool) voters;
    }
    
    mapping(uint => Request) public requests;
    uint public numRequests; // mapping does not use or increment indexes automatically (like an array does). 
    // Cannot use array neither because it cannot contained Struct variables.
    
    constructor(uint _goal, uint _deadline){
        goal = _goal;
        deadline = block.timestamp + _deadline;
        minimumContribution = 100 wei;
        admin =msg.sender;
    }
    
    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);
    
    function contribute() public payable{
        require(block.timestamp < deadline, "Deadline has passed !");
        require(msg.value >= minimumContribution, "minimumContribution not met");
        
        if (contributors[msg.sender] == 0){
            noOfContributors++; //add 1
        }
        
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
        
        emit ContributeEvent(msg.sender, msg.value);
    }
    
    receive() payable external{
        contribute();
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function getRefund() public payable{
        require(block.timestamp > deadline && raisedAmount < goal, "Deadline has not passed or raisedAmount is reached !");
        require(contributors[msg.sender] > 0);
        
        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        
        contributors[msg.sender] = 0;
        recipient.transfer(value);
        // OR payable(msg.sender).transfer(contributors[msg.sender]);
        
    }
    
    modifier onlyAdmin(){
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin{
        Request storage newRequest = requests[numRequests]; //requests start from 0 (numRequests by deault), 
        numRequests++;
        
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false; //useless because it s the default value
        newRequest.noOfVoters = 0;
        
        emit CreateRequestEvent(_description, _recipient, _value);
    }
    
    function voteRequest(uint _requestNo) public{
        require(_requestNo <= numRequests, "requestNo you voted for doesn't exist");
        require(contributors[msg.sender] > 0, "you must be a contributor to vote");
        Request storage thisRequest = requests[_requestNo];
        
        require(thisRequest.voters[msg.sender] == false, "you have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }
    
    function makePayment(uint _requestNo) public onlyAdmin{
        require(raisedAmount >= goal);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "the request has been completed");
        require(thisRequest.noOfVoters > noOfContributors / 2, "less than 50% of voters");
        
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
        
        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
}
