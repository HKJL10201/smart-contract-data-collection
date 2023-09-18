// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract LFX is ERC20 {
  constructor(uint amount) ERC20('LotteFan', 'LFX') {
    _mint(msg.sender, amount);
  }

  function burn(uint amount) public {
    _burn(msg.sender, amount);
  }
}
