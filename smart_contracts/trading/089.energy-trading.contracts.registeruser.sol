pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol"

contract registerUser {
  uint registrationFee = 0.001 ether;

  mapping (address => bool) registeredUser;
  address[] registeredUsers;

  function registerUser() external {
    require(msg.value == registrationFee);
    registeredUser[msg.sender] = true;
    registeredUsers.push(msg.sender);
  }

  modifier isRegistered() {
    require(registeredUser[msg.sender] == true);
    _;
  }
}