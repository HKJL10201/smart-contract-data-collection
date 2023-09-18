// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract ThriveCoinVoterList is AccessControlEnumerable {
  mapping(address => bool) internal _voters;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /**
   * @dev Add a voter. Only callable by accounts with DEFAULT_ADMIN_ROLE.
   *
   * @param voter - The address that will get the voter status.
   */
  function addVoter(address voter) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _voters[voter] = true;
  }

  /**
   * @dev Add a voter. Only callable by accounts with DEFAULT_ADMIN_ROLE.
   *
   * @param voters - The addresses that will get the voter status.
   */
  function addVoters(address[] calldata voters) public onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i = 0; i < voters.length; i++) {
      _voters[voters[i]] = true;
    }
  }

  /**
   * @dev Remove a voter. Only callable by accounts with DEFAULT_ADMIN_ROLE.
   *
   * @param voter - The address that will lose the voter status.
   */
  function removeVoter(address voter) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _voters[voter] = false;
  }

  /**
   * @dev Remove a voter. Only callable by accounts with DEFAULT_ADMIN_ROLE.
   *
   * @param voters - The address that will lose the voter status.
   */
  function removeVoters(address[] calldata voters) public onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i = 0; i < voters.length; i++) {
      _voters[voters[i]] = false;
    }
  }

  /**
   * @dev Check if an address is a voter.
   *
   * @param account - The address to check.
   */
  function hasVoteRight(address account) public view returns (bool) {
    return _voters[account];
  }
}
