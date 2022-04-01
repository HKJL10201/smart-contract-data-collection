//SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.6.0 < 0.9.0;

contract CrowdFunding{

    //contributors to request number
    mapping(address => uint) public contributors;
    address public admin;
    uint public noOfContributors;
    uint public deadline; //timestamp
    uint public minimumContribution;
    uint public goal;
    uint public raisedAmount;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    //request id to request
    mapping(uint => Request) public requests;

    uint public numRequests;

    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);

    constructor(uint _goal, uint _deadline){

        goal = _goal;
        deadline = block.timestamp + _deadline;
        minimumContribution = 100 wei;
        admin = msg.sender;
    }

    //contribute to the campaign
    function contribute() public payable{

        //check if campaign is running
        require(block.timestamp < deadline,"deadline has passed");
        //check if minimumContribution is met
        require(msg.value >= minimumContribution,"Minimum Contribution not met!");

        //if sender is not a contributor
        if(contributors[msg.sender] == 0){

            //increment contributor count
            noOfContributors ++;
        }

        //store the constructor's contribution
        contributors[msg.sender] += msg.value;

        //increment the money raised
        raisedAmount += msg.value;

        //emit event
        emit ContributeEvent(msg.sender, msg.value);
    }

    //function to accept ethers
    receive() payable external{

        contribute();
    }

    //get the contract's balance
    function getBalance() public view returns(uint){

        return address(this).balance;
    }

    //get the refund
    function getRefund() public{

        //check if campaign is ended
        require(block.timestamp > deadline && raisedAmount < goal);

        //check if sender is a contributor
        require(contributors[msg.sender] > 0);

        address payable recipient = payable(msg.sender);

        //get the money contributed by sender
        uint value = contributors[msg.sender];

        //transfer the money to sender
        recipient.transfer(value);

        //reset the contribution of sender
        contributors[msg.sender] = 0;
    }

    modifier onlyAdmin(){

        require(msg.sender == admin,"only admin can call the request");
        _;
    }

    //create a campaign
    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin{

        //get the instance of campaign request in mapping
        Request storage newRequest = requests[numRequests];

        //increment the campaign request count
        numRequests ++;

        //set the campaign request
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value =  _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;

        //emit event
        emit CreateRequestEvent(_description, _recipient, _value);
    }

    //vote for a campaign request
    function voteRequest(uint _requestNo) public{

        //check if voter is a contributor
        require(contributors[msg.sender] > 0,"you must be a contributor to vote");

        //get the instance of request stored with mapping
        Request storage thisRequest = requests[_requestNo];

        //sender should not have voted for this campaign request before
        require(thisRequest.voters[msg.sender] == false,"you have already voted");

        //give the vote
        thisRequest.voters[msg.sender] = true;

        //increment voters count for campaign request
        thisRequest.noOfVoters ++;
    }

    //make payment after campaign ends
    function makePayment(uint _requestNo) public onlyAdmin{

        //check if goal is reached
        require(raisedAmount >= goal);

        //get the instance of request stored with mapping
        Request storage thisRequest = requests[_requestNo];

        //the campaign request should not be completed already
        require(thisRequest.completed == false,"the request has been completed");

        //campaign should have 50% votes of total voters
        require(thisRequest.noOfVoters > noOfContributors / 2);

        //transfer the money to recipient of campaign request
        thisRequest.recipient.transfer(thisRequest.value);

        //set the campaign request to completed
        thisRequest.completed = true;

        //emit event
        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }


}