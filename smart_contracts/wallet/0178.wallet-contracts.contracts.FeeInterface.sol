pragma solidity ^0.4.24;

contract FeeInterface {
  function getFee(uint _base, uint _amount) external view returns (uint256 fee);
}