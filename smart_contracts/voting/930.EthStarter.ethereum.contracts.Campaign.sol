// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract CampaignFactory {
    address[] campaigns;
    
    function createCampaign(uint minimum) public payable {
        address campaign = address(new Campaign(msg.sender, minimum));
        campaigns.push(campaign);
    }

    function getCampaigns() public view returns (address[] memory) {
        return campaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    address public manager;
    uint public minimumContribution;
    uint public approverCount;
    mapping(address => bool) public approvers;
    mapping(uint => Request) public requests;
    uint public requestCount;

    modifier restricted() {
        require(
            msg.sender == manager,
            "Only manager can make this transaction."
        );
        _;
    }

    modifier approver() {
        require(
            approvers[msg.sender],
            "Only contributors can approve requests."
        );
        _;
    }

    modifier notFinalized(uint index) {
        require(
            !requests[index].complete,
            "This request has already been completed."
        );
        _;
    }

    constructor (address creator, uint minimum) {
        manager = creator;
        minimumContribution = minimum;
        approverCount = 0;
        requestCount = 0;
    }

    function contribute() public payable {
        require(
            msg.value >= minimumContribution,
            "Contribution amount is less than the minimum."
        );

        if(approvers[msg.sender] != true) {
            approvers[msg.sender] = true;
            approverCount++;
        }
    }

    function createRequest(string calldata description, uint value, address recipient) external restricted {
        Request storage request = requests[requestCount++];
        request.description = description;
        request.value = value;
        request.recipient = recipient;
        request.complete = false;
        request.approvalCount = 0;
    }

    function approveRequest(uint index) public approver notFinalized(index) {
        Request storage request = requests[index];

        require(
            !request.approvals[msg.sender],
            "You have already approved this request."
        );

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    function revokeApproval(uint index) public approver notFinalized(index) {
        Request storage request = requests[index];

        require(
            request.approvals[msg.sender],
            "You haven't approved this request."
        );

        if(requests[index].approvals[msg.sender] == true) {
            requests[index].approvals[msg.sender] = false;
            requests[index].approvalCount--;
        }
    }

    function finalizeRequest(uint index) public restricted notFinalized(index) {
        Request storage request = requests[index];

        require(
            request.approvalCount > approverCount/2,
            "This request has not yet reached required majority."
        );

        request.complete = true;
        payable(request.recipient).transfer(request.value);
    }

    function getMetrics() public view returns (
        uint, uint, uint, uint, address
    ) {
        return (
            minimumContribution,
            address(this).balance,
            requestCount,
            approverCount,
            manager
        );
    }

    function isApprover(uint index, address person) public view returns (bool) {
        return requests[index].approvals[person];
    }
}
