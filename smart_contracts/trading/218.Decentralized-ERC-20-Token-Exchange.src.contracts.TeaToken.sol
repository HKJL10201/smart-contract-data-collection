pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TeaToken is ERC20 {
  constructor () public ERC20("TeaToken", "TEA") {
    _mint(msg.sender, 500000 * 10 ** uint(decimals()));
  }
}