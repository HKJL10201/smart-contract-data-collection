// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSig {
    address[] public approvers;
    uint256 public immutable quorum;

    struct Transfer {
        uint256 id;
        uint256 amount;
        address payable to;
        uint256 approvals;
        bool sent;
    }

    mapping(uint256 => Transfer) public transfers;
    uint256 public nextId;
    mapping(address => mapping(uint256 => bool)) public approvals;

    constructor(address[] memory _approvers, uint256 _quorum) payable {
        approvers = _approvers;
        quorum = _quorum;
    }

    function createTransfer(uint256 _amount, address payable _to)
        external
        onlyApprover
    {
        transfers[nextId] = Transfer(nextId, _amount, _to, 0, false);
        nextId++;
    }

    function sendTransfer(uint256 _id) external onlyApprover {
        require(transfers[_id].sent == false, "transfer has already been sent");
        if (approvals[msg.sender][_id] == false) {
            approvals[msg.sender][_id] = true;
            transfers[_id].approvals++;
        }

        if (transfers[_id].approvals >= quorum) {
            transfers[_id].sent = true;
            address payable to = transfers[_id].to;
            uint256 amount = transfers[_id].amount;
            to.transfer(amount);
        }
    }

    modifier onlyApprover() {
        bool allowed = false;
        for (uint256 i = 0; i < approvers.length; i++) {
            if (approvers[i] == msg.sender) {
                allowed = true;
                break;
            }
        }

        require(allowed == true, "only approver allowed");
        _;
    }
}
