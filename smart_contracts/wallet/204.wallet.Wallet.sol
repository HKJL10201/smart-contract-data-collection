// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Wallet {
  address[] public approvers;
  uint public quorum;

  struct Transfer {
    uint id;
    uint amount;
    address payable to;
    uint approvals;
    bool sent;
  }

  mapping

  constructor(address[] memory _approvers, uint _quorum) {
    approvers = _approvers;
    quorum = _quorum;
  }

  function getApprovers() external view returns (address[] memory) {
    return approvers;
  }

}
