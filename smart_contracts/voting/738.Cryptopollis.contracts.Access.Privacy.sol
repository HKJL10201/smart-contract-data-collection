// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Accesses
 * @dev Library for managing voter access to poll
 */
library Privacy {
    struct Access {
        mapping (address => bool) access;
        }

  /**
   * @dev give access to voter
   */
   function add(Access storage access, address pollId) internal {
     access.access[pollId] = true;
     }

  /**
   * @dev remove access from voter
   */
  function remove(Access storage access, address pollId) internal {
      access.access[pollId] = false;
  }

  /**
   * @dev check if voter has access
   * @return bool
   */
  function has(Access storage access, address pollId) internal view returns (bool)
  {
    return access.access[pollId];
  }
}
