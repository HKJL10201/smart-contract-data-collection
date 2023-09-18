// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Campaign {

    /** ATTRIBUTES */

    address public manager;
    uint minimumContribution;
    uint numRequests;
    uint contributorCount;
    mapping(uint => Request) public requests;
    mapping(address => bool) public contributors;

    /** STRUCTS */

    struct Request {
        string description;
        uint value;
        address payable recipient;
        bool complete;
        mapping(address => bool) approvals;
        uint approvalCount;
    }

    /** MODIFIERS */
    
    modifier ismanager {
        require(msg.sender == manager);
        _;
    }

    modifier payedminimum {
        require(msg.value > minimumContribution - 1);
        _;
    }

    modifier contributor {
        require(contributors[msg.sender]);
        _;
    }

    /** METHODS */

    constructor(uint _minimum) {
        manager = msg.sender;
        minimumContribution = _minimum;
    }

    function contribute() public payable payedminimum {
        contributors[msg.sender] = true;
        contributorCount++;
    }

    function createRequest(string memory _description, uint _value, address payable _recipient) public ismanager {
        Request storage newRequest = requests[numRequests++];
        newRequest.description = _description;
        newRequest.value = _value;
        newRequest.recipient = _recipient;
        newRequest.complete = false;
        newRequest.approvalCount = 0;
    }

    function approveRequest(uint _index) public contributor {
        Request storage req = requests[_index];
        
        require(!req.approvals[msg.sender]);

        req.approvalCount++;
        req.approvals[msg.sender] = true;
    }

    function finalizeRequest(uint _index) public ismanager {
        Request storage req = requests[_index];

        require(req.approvalCount > (contributorCount / 2));

        req.complete = true;
    }
}