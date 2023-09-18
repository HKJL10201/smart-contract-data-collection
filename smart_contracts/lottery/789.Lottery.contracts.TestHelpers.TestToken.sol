// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is IERC20, ERC20 {

  constructor(address ad1, address ad2, address ad3, address ad4, address ad5) ERC20 ("tToken", "TT") {
    _mint(ad1, 10000000000000000000000000000);
    _mint(ad2, 10000000000000000000000000000);
    _mint(ad3, 10000000000000000000000000000);
    _mint(ad4, 10000000000000000000000000000);
    _mint(ad5, 10000000000000000000000000000);
  }

}
