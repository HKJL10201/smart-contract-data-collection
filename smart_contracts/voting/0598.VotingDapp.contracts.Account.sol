pragma solidity ^0.4.15;

contract Account {
  string public name;
  address public owner;

  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  function Account() {
    owner = msg.sender;
  }

  function setName(string _name) onlyOwner {
    name = _name;
  }
}