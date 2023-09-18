pragma solidity ^0.5.3;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MikeToken is ERC20 {
  string public constant NAME = 'MikeToken';
  string public constant SYMBOL = 'MIKE';
  uint8 public constant DECIMALS = 18;
  uint256 public constant INITIAL_SUPPLY = 1000000 * (10**uint256(DECIMALS));

  constructor() public {
    _mint(msg.sender, INITIAL_SUPPLY);
  }
}
