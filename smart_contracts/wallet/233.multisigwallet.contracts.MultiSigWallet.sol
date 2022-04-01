// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract MultiSigWallet {
    address[] public approvers;
    uint public quorum;

    struct Transfer {
        uint id;
        uint amount;
        address payable to;
        uint approvals;
        bool sent;
    }
    mapping(uint => Transfer) public transfers;
    mapping(address => mapping(uint => bool)) public approvals;

    uint public nextId;

    constructor(address[] memory _approvers, uint _quorum) payable {
        approvers = _approvers;
        quorum = _quorum;
    }

    function createTransfer(uint amount, address payable to) external onlyApprover(){
        Transfer storage t = transfers[nextId];
        t.id = nextId;
        t.amount = amount;
        t.to = to;
        t.approvals = 0;
        t.sent = false;

        nextId++;
    }

    function sendTransfer(uint id) external onlyApprover() {
        require(transfers[id].sent == false, "Transfer already sent.");

        if (approvals[msg.sender][id] == false) {
            approvals[msg.sender][id] = true;

            transfers[id].approvals++;
        }

        if (transfers[id].approvals >= quorum) {
            transfers[id].sent = true;

            address payable to = transfers[id].to;
            uint amount = transfers[id].amount;

            to.transfer(amount);

            return;
        }
    }

    modifier onlyApprover() {
        bool allowed = false;

        for (uint i = 0; i < approvers.length; i++) {
            if (approvers[i] == msg.sender) {
                allowed = true;
            }
        }

        require(allowed == true, "Only approver allowed");
        _;
    }
}
