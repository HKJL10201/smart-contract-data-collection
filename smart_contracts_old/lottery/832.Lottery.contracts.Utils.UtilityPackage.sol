// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UtilityPackage {

  address public sweeper;

  constructor() {
    sweeper = _sender();
  }

  function _sender() internal view returns (address) {
    return msg.sender;
  }

  function _timestamp() internal view returns (uint) {
    return block.timestamp;
  }

  function sweep(address tokenToSweep) public returns (bool) {
    require(_sender() == sweeper, "must be the sweeper");
    uint tokenBalance = IERC20(tokenToSweep).balanceOf(address(this));
    if (tokenBalance > 0) {
      IERC20(tokenToSweep).transfer(sweeper, tokenBalance);
    }
    return true;
  }

  function changeSweeper(address newSweeper) public returns (bool) {
    require(_sender() == sweeper, "Only the sweeper can assign a replacement");
    sweeper = newSweeper;
    return true;
  }

}
