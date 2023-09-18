pragma solidity ^0.4.17;

contract CampaignFactory {
    address[] public deployedCampaigns;
    
    function createCampaign(uint minContribution) public {
        address newCampaign = new Campaign(minContribution, msg.sender);
        deployedCampaigns.push(newCampaign);
    }
    
    function getDeployedCampaigns() public view returns (address[]) {
        return deployedCampaigns;
    }
}

contract Campaign {
    // request to spend campaign funds
    // struct is a type definition (like Typescript interface)
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }
    
    Request[] public requests;
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;  
    uint public approversCount;
    
    // ensure only manager can call function
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    constructor(uint minContribution, address creator) public {
        // address of contract creator
        manager = creator;
        minimumContribution = minContribution;
    }
    
    function contribute() public payable {
        require(msg.value > minimumContribution);
        
        approvers[msg.sender] = true;
        approversCount++;
    }
    
    function createRequest(string description, uint value, address recipient) public restricted {
        // only have to initialize value types, not reference types (ie 'approvers' mapping)
        Request memory newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete: false,
            approvalCount: 0
        });
        
        requests.push(newRequest);
    }
    
    // 'index' arg is index of request we're trying to approve
    function approveRequest(uint index) public {
        Request storage request = requests[index];
        
        // make sure person has contributed
        require(approvers[msg.sender]);
        // make sure user hasn't already voted
        require(!request.approvals[msg.sender]);
        
        // mark user as having voted
        request.approvals[msg.sender] = true;
        // increment 'yes' votes
        request.approvalCount++;
    }
    
    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];
        
        require(!request.complete);
        require(request.approvalCount > (approversCount / 2));
        
        // send the recipient all the money int the request acct
        request.recipient.transfer(request.value);
        request.complete = true;
    }

    function getSummary() public view returns (
        uint, uint, uint, uint, address
    ) {
        return (
            minimumContribution,
            this.balance,
            requests.length,
            approversCount,
            manager
      );
    }

    function getRequestsCount() public view returns (uint) {
        return requests.length;
    }
}
