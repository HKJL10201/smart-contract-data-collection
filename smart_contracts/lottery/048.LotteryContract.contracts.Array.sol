// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Array {
  uint[] public uintArray;
  string[] public stringArray;

  constructor () {
    uintArray.push(1);
    uintArray.push(2);
    uintArray.push(4);
    uintArray.push(16);
    stringArray.push("Ok");
  }

  function getFirstString() public view returns (string memory) {
    return stringArray[0];
  }

  function getStringArray() public view returns (string[] memory) {
    return stringArray;
  }

  function getArrayLength() public view returns (uint) {
    return uintArray.length;
  }
}