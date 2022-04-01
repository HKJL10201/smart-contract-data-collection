// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <=0.6.12;

contract CampaignFactory {
    address[] public deployedCampaigns;
    
    function createCampaign(uint minimum) public {
        Campaign newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(address(newCampaign));
    }
    
    // 'view' indicates no data in the contract is modified by this function
    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    } 
}

contract Campaign {
    struct Request {
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }
    
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    Request[] public requests;
    uint public approversCount;
    
    
    // function modifier to make so that only a manager 
    // is to be able to access this function
    // modifiers always go above the constructor
    modifier restricted() {
        require(msg.sender == manager);
        
        // modifier 'pastes' the modified functon to here where the underscore is!
        _;
    }
    
    constructor(uint minimum, address creator) public {
        manager = creator; 
        minimumContribution = minimum;
    }
    
    // 'payable' keyword is what allows this function to receive some amount of money
    function contribute() public payable {
        // 'value' is the amount in wei that someone has sent along with the transaction that is targetting this function
        // if value is less that minimumContribution the require function will throw an exception and hault execution of this function
        require(msg.value > minimumContribution);
        approvers[msg.sender] = true;
        approversCount++;
    }
    
    
    function createRequest(string memory description, uint value, address payable recipient) public restricted {
        Request memory newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete: false,
            approvalCount: 0
        });
    
        requests.push(newRequest);
    }
    
    function approveRequest(uint index) public {
        // We use storage here because we want to be referencing the actual storage version of the request so we can persist changes
        // If we had used 'memory' we would have made a copy of the request and changes would not persist
        Request storage request = requests[index];
        
        
        // 'msg' is a global variable, 'sender' is who is attempting to create the contract
        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);
        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }
    
    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];
        require(request.approvalCount > (approversCount / 2));
        require(!request.complete);
        request.recipient.transfer(request.value);
        request.complete = true;
    }
    
}

