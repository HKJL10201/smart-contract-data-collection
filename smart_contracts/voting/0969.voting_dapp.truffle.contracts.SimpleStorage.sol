// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract SimpleStorage {
  uint256 value;
  string greetings;

  event valueChanged(uint _val);

  function read() public view returns (uint256) {
    return value;
  }

  function write(uint256 newValue) public {
    value = newValue;
    emit valueChanged(newValue);
  }

  function setGreet(string memory _greet) public {
    require( bytes(_greet).length != 0,"String should not be NULL");
    greetings = _greet;
  }

  function greet() public view returns (string memory) {
    return greetings;
  }
}
