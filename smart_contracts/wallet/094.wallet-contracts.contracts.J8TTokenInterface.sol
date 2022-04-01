pragma solidity ^0.4.24;

contract J8TTokenInterface {
  function balanceOf(address who) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  function approve(address spender, uint256 value) public returns (bool);
}