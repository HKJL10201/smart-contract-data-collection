// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Storage {
  uint data;
  constructor() public {
    data = 0;
  }

  function set(uint value) public {
    data = value;
  }

  function get() public view returns (uint) {
    return data;
  }
  
}
