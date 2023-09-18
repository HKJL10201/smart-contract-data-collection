// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Owned {
  address public owner;

  // init on deployment
  constructor() {
      owner = msg.sender;
  }

  modifier onlyOwner() {
      require(msg.sender == owner, "Only Owner can call this function");
      _;
  }
}
