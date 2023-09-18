// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Incentivized {

  address public incentiveToken;
  uint public amountPerEntry;

  constructor(address _incentiveToken, uint _amountPerEntry) {
    incentiveToken = _incentiveToken;
    amountPerEntry = _amountPerEntry;
  }

  function fund(uint _amount) public returns (bool) {
    IERC20(incentiveToken).transferFrom(msg.sender, address(this), _amount);
    return true;
  }

}
