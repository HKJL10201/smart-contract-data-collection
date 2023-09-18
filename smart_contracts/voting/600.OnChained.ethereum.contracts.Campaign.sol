pragma solidity ^0.4.22;

contract CampaignManager {
    
    address[] public deployedContracts;
    
    function newCampaign (uint _minimumContribution) public {
        address new_campaign = new Campaign(msg.sender, _minimumContribution);
        deployedContracts.push(new_campaign);
    }
    
    function getDeployedContracts() public view returns (address[]) {
        return deployedContracts;
    }
    
}

contract Campaign {
    
    struct Request {
        string description;
        uint amount; // wei
        address recipient;
        bool complete;
        mapping (address => bool) approvals;
        uint approvalCount;
    }
    
    address public manager;
    uint public minimumContribution; // wei
    
    mapping (address => bool) public approvers;
    Request[] public requests;
    uint public approversCount = 0;
    
    constructor (address owner, uint minContrib) public {
        manager = owner;
        minimumContribution = minContrib;
        
    }
    
    function contribute() public payable {
        require(msg.value >= minimumContribution);
        require(!approvers[msg.sender]);
        
        approvers[msg.sender] = true;
        approversCount ++;
    }
    
    modifier onlyBy(address _account)
    {
        require(
            msg.sender == _account,
            "Sender not authorized."
        );
        _;
    } 
    
    function createRequest(string _description, uint _amount, address _recipient) 
        public onlyBy(manager) {
        Request memory request = Request({
            description: _description,
            amount: _amount,
            recipient: _recipient,
            complete: false,
            approvalCount: 0
        });
        
        requests.push(request);
    }
    
    function approveRequest(uint reqIndex) public {
        require(approvers[msg.sender]);
        Request storage request = requests[reqIndex];
        
        require(!request.approvals[msg.sender]);
        request.approvals[msg.sender] = true;
        request.approvalCount ++;
        
    } 
    
    function finalizeRequest(uint reqIndex) public onlyBy(manager){
        
        Request storage request = requests[reqIndex];
        require (!request.complete, "can't approve req already complete");
        require ( request.approvalCount > approversCount / 2, "require at least half approvers' approval");
        
        request.recipient.transfer(request.amount);
        request.complete = true;
    }
    
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function getSummary() public view returns (
      uint, uint, uint, uint, address
      ) {
        return (
          minimumContribution,
          address(this).balance,
          requests.length,
          approversCount,
          manager
        );
    }
}