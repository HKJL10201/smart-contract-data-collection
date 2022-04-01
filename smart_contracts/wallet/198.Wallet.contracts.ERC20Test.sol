// SPDX-License-Identifier: None
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ERC20Test
 *
 * @dev This contract was used for testing purposes only, do not deploy
 */

contract ERC20Test is ERC20 {

  constructor() ERC20('Test Token', 'TT') {
    _mint(msg.sender, 1000);
  }
}
