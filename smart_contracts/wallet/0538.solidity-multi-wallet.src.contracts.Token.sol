// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Token is ERC20 {
 constructor(string memory _name, string memory _symbol, uint _supply, uint _decimals) ERC20(_name, _symbol) {
  _mint(msg.sender, _supply * 10**_decimals);
 }
}
