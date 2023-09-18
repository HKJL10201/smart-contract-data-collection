// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
  /**
   *
   * @param minDelay How long you ahve to wait before executing.
   * @param proposers is the list of addresses that can propose.
   * @param executors  is the list of addresses who can execute when a proposal passes.
   */
  constructor(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors
  ) TimelockController(minDelay, proposers, executors, msg.sender) {}
}
