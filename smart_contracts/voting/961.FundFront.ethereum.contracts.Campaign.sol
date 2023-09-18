pragma solidity ^0.4.17;


contract CampaignFactory {
    address[] public deployedCampagins;

    function createCampaign(uint256 minimun) public {
        address newCampaign = new Campaign(minimun, msg.sender);
        deployedCampagins.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (address[]) {
        return deployedCampagins;
    }
}


contract Campaign {
    struct Request {
        string description;
        uint256 value;
        address recipient;
        bool complete;
        mapping(address => bool) approvals;
        uint256 approvalsCount;
    }

    Request[] public request;
    address public manager;
    uint256 public minimumContribution;
    mapping(address => bool) public approvers;
    uint256 approversCount;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function Campaign(uint256 minimum, address creator) public {
        manager = creator;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution);
        approversCount++;

        approvers[msg.sender] = true;
    }

    function createRequest(string description, uint256 value, address recipient)
        public
        restricted
    {
        Request memory newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete: false,
            approvalsCount: 0
        });

        request.push(newRequest);
    }

    function approveRequest(uint256 index) public {
        Request storage req = request[index];

        require(approvers[msg.sender]);
        require(!req.approvals[msg.sender]);

        req.approvals[msg.sender] = true;
        req.approvalsCount++;
    }

    function finalizeRequest(uint256 index) public restricted {
        Request storage req = request[index];

        require(req.approvalsCount > (approversCount / 2));
        require(!req.complete);

        req.recipient.transfer(req.value);
        req.complete = true;
    }

    function getSummary()
        public
        view
        returns (uint256, uint256, uint256, uint256, address)
    {
        return (
            minimumContribution,
            this.balance,
            request.length,
            approversCount,
            manager
        );
    }

    function getRequestsCount() public view returns (uint256) {
        return request.length;
    }

    function getApproversCount() public view returns (uint256) {
        return approversCount;
    }
}
