// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract CampaignHub {
    address[] public campaigns;

    function createCampaign(
        string memory title,
        string memory description,
        uint256 amount,
        uint256 votingPercentage
    ) public {
        Campaign newCampaign = new Campaign(
            msg.sender,
            title,
            description,
            amount,
            votingPercentage
        );
        campaigns.push(payable(address(newCampaign)));
    }

    function getCampaigns() public view returns (address[] memory) {
        return campaigns;
    }
}

contract Campaign {
    struct Request {
        string requestTitle;
        string requestDescription;
        uint256 value;
        address recepient;
        // Votes --- 0: Not voted(default), 1: Yes, 2: No, 3: Don't Care.
        mapping(address => uint8) votes;
        uint256 yesCount;
        uint256 noCount;
        uint256 votesCount;
        bool complete;
    }

    address public owner;
    string public campaignTitle;
    string public campaignDescription;
    uint256 public approvalAmount;
    uint256 public minVotingPercentage;

    mapping(address => uint256) public contributors;
    mapping(address => bool) public approvers;
    uint256 public contributorsCount;
    uint256 public approversCount;

    mapping(uint256 => Request) public requests;
    uint256 public requestsCount;

    constructor(
        address sender,
        string memory title,
        string memory description,
        uint256 amount,
        uint256 votingPercentage
    ) {
        owner = sender;
        campaignTitle = title;
        campaignDescription = description;
        approvalAmount = amount;
        minVotingPercentage = votingPercentage;
        contributorsCount = 0;
        approversCount = 0;
        requestsCount = 0;
    }

    modifier restricted() {
        require(msg.sender == owner, "Sender is not Owner");
        _;
    }

    function contribute() public payable {
        if (contributors[msg.sender] == 0) contributorsCount++;
        contributors[msg.sender] += msg.value;
    }

    function becomeApprover() public {
        require(
            contributors[msg.sender] >= approvalAmount,
            "Not enough contribution"
        );
        approvers[msg.sender] = true;
        approversCount++;
    }

    function revokeApprover() public {
        require(approvers[msg.sender], "Already not an approver");
        approvers[msg.sender] = false;
        approversCount--;
    }

    function addRequest(
        string memory title,
        string memory description,
        uint256 value,
        address recepient
    ) public restricted {
        Request storage newRequest = requests[requestsCount];
        requestsCount++;
        newRequest.requestTitle = title;
        newRequest.requestDescription = description;
        newRequest.value = value;
        newRequest.recepient = recepient;
        newRequest.yesCount = 0;
        newRequest.noCount = 0;
        newRequest.votesCount = 0;
        newRequest.complete = false;
    }

    function approveRequest(uint256 requestId, uint8 vote) public {
        require(approvers[msg.sender], "Not an approver");
        require(requestId < requestsCount, "Invalid id");
        Request storage request = requests[requestId];
        require(request.votes[msg.sender] == 0, "Already voted");
        request.votes[msg.sender] = vote;
        request.votesCount++;
        if (vote == 1) {
            request.yesCount++;
        } else if (vote == 2) {
            request.noCount++;
        }
    }

    function finalizeRequest(uint256 requestId) public restricted {
        require(requestId < requestsCount, "Invalid id");
        Request storage request = requests[requestId];
        require(!requests[requestId].complete, "Already finalized");
        require(
            (request.votesCount * 100) / approversCount >= minVotingPercentage,
            "Not enough approvers voted"
        );
        require(
            request.yesCount > request.noCount,
            "Not enough people approved"
        );
        require(address(this).balance >= request.value, "Not enough funds");
        payable(request.recepient).transfer(request.value);
        request.complete = true;
    }

    function summarize() public view returns (
        address,
        string memory,
        string memory,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ){
        return (
            owner,
            campaignTitle,
            campaignDescription,
            address(this).balance,
            approvalAmount,
            minVotingPercentage,
            contributorsCount,
            approversCount
        );
    }
}
