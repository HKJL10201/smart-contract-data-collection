// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
  uint256 private value;

  event ValueChanged(uint256 newValue);

  function setValue(uint256 _newValue) public onlyOwner {
    value = _newValue;
    emit ValueChanged(_newValue);
  }

  function getValue() public view returns (uint256) {
    return value;
  }
}
