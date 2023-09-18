// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.17;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint256 minimum) public {
        address newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (address[]) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        uint256 value;
        string description;
        address recipient;
        bool completed;
        mapping(address => bool) votes;
        uint256 totalVotes;
    }

    address public manager;
    uint256 public minimumContribution;
    mapping(address => bool) public approvers;
    address[] list_of_approvers;
    Request[] public requests;

    constructor(uint256 _minimumContribution, address creator) public {
        manager = creator;
        minimumContribution = _minimumContribution;
    }

    function contribute() public payable {
        require(msg.value >= minimumContribution);
        if (!approvers[msg.sender]) {
            list_of_approvers.push(msg.sender);
        }
        approvers[msg.sender] = true;
    }

    function createRequest(
        string description,
        uint256 value,
        address recipient
    ) public onlyManager {
        Request memory newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            completed: false,
            totalVotes: 0
        });
        requests.push(newRequest);
    }

    function getApprovers() public view returns (address[]) {
        return list_of_approvers;
    }

    function approve(uint256 request_index) public onlyApprovers {
        require(request_index < requests.length);
        Request storage request = requests[request_index];
        require(!request.votes[msg.sender]);
        request.votes[msg.sender] = true;
        request.totalVotes++;
    }

    function finalizeRequest(uint256 request_index) public onlyManager {
        require(request_index < requests.length);
        Request storage request = requests[request_index];

        require(!request.completed);
        uint256 total_approvers = list_of_approvers.length;
        require(request.totalVotes > total_approvers / 2);
        require(address(this).balance >= request.value);
        request.completed = true;

        request.recipient.transfer(request.value);
    }

    modifier onlyApprovers() {
        require(approvers[msg.sender]);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    function getRequestCount() public view returns (uint256) {
        return (requests.length);
    }

    function getRequestStatus(uint256 index, address user)
        public
        view
        returns (
            uint256,
            string,
            address,
            bool,
            bool,
            uint256
        )
    {
        Request storage r = requests[index];

        return (
            r.value,
            r.description,
            r.recipient,
            r.completed,
            r.votes[user],
            r.totalVotes
        );
    }

    function getSummary()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        uint256 total_approvers = list_of_approvers.length;
        return (
            minimumContribution,
            address(this).balance,
            requests.length,
            total_approvers,
            manager
        );
    }
}
