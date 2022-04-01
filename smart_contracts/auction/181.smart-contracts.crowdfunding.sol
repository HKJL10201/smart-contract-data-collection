// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;


contract CrowdFunding{
    mapping(address => uint) public contributors;
    address public admin;
    uint public numberOfContributors;
    uint public minimumContribution;
    uint public deadline; // timestamp
    uint public goal;
    uint public raisedAmount;
    
    struct SpendingRequest{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint numberOfVoters;
        mapping(address => bool) voters;
    }
    
    mapping(uint => SpendingRequest) public spendingRequests;
    uint public numberOfSpendingRequests;
    
    constructor(uint _goal, uint _deadline){
        goal = _goal;
        deadline = block.timestamp + _deadline;
        minimumContribution = 100 wei;
        admin = msg.sender;
    }
    
    event ContributeEvent(address _sender, uint value);
    event CreateSpendingRequestEvent(string _description, address _recipient, uint value);
    event MakePaymentEvent(address _recipient, uint value);
    
    function contribute() public payable{
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value >= minimumContribution, "Minimum contribution value not met");
        
        if(contributors[msg.sender] == 0){
            numberOfContributors++;
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
    
    function getRefund() public{
        require(block.timestamp > deadline && raisedAmount < goal);
        require(contributors[msg.sender] > 0);
        
        address payable recipent = payable(msg.sender);
        uint value = contributors[msg.sender];
        
        recipent.transfer(value);
        contributors[msg.sender] = 0;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    function createSpendingRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin{
        SpendingRequest storage newRequest = spendingRequests[numberOfSpendingRequests];
        numberOfSpendingRequests++;
        
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.numberOfVoters = 0;
        
        emit CreateSpendingRequestEvent(_description, _recipient, _value);
    }
    
    function voteForSpendingRequest(uint _spendingRequestNumber) public{
        require(_spendingRequestNumber < numberOfSpendingRequests, "Spending request with this id does not exist");
        require(contributors[msg.sender] > 0, "You must be a contributor to vote");
        SpendingRequest storage thisRequest = spendingRequests[_spendingRequestNumber];
        
        require(thisRequest.voters[msg.sender] == false, "You have already voted!");
        thisRequest.voters[msg.sender] = true;
        thisRequest.numberOfVoters++;
    }
    
    function makePayment(uint _spendingRequestNumber) public onlyAdmin{
        require(raisedAmount >= goal, "Not enough ether collected");
        SpendingRequest storage thisRequest = spendingRequests[_spendingRequestNumber];
        require(thisRequest.completed == false, "The request has been completed");
        require(thisRequest.numberOfVoters > numberOfContributors / 2, "Less than 51% of voters voted for this spending request");
        
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
        
        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
}


