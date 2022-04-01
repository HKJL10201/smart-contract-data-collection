// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract MultiSigWallet {
    address[] public approvers;
    uint256 public quorum;

    struct Transfer {
        uint256 id;
        uint256 amount;
        address payable to;
        uint256 approvals;
        bool sent;
    }

    Transfer[] public transfers;
    uint256 public nextId;

    mapping(address => mapping(uint256 => bool)) public approvals;

    constructor(address[] memory _approvers, uint256 _quorum) {
        approvers = _approvers;
        quorum = _quorum;
    }

    function getApprovers() public view returns (address[] memory) {
        return approvers;
    }

    function getTransfers() public view returns (Transfer[] memory) {
        return transfers;
    }

    function craeteTransfer(uint256 amount, address payable to)
        external
        onlyApprover
    {
        transfers.push(Transfer(nextId, amount, to, 0, false));

        nextId++;
    }

    function approveTransfers(uint256 id) external onlyApprover {
        require(
            transfers[id].sent == false,
            "Transation has alredy been sent!"
        );
        require(
            approvals[msg.sender][id] == false,
            "can't Approve Trasnation Twice!"
        );

        approvals[msg.sender][id] = true;
        transfers[id].approvals++;

        if (transfers[id].approvals >= quorum) {
            transfers[id].sent = true;
            address payable to = transfers[id].to;
            uint256 amount = transfers[id].amount;
            to.transfer(amount);
        }
    }

    receive() external payable {}

    modifier onlyApprover() {
        bool allowed = false;
        for (uint256 i = 0; i < approvers.length; i++) {
            if (approvers[i] == msg.sender) {
                allowed = true;
            }
        }
        require(allowed, "You not a Approver!");
        _;
    }

    function checkApprovals(address _addr, uint256 id)
        external
        view
        returns (bool)
    {
        return approvals[_addr][id];
    }
}
