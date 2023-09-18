pragma solidity ^0.4.2;

contract SimpleStore {
  uint storedData;

  function set(uint x) public {
    storedData = x;
  }

  function get() constant public returns (uint retVal) {
    return storedData;  
  }
}