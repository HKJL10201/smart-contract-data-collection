// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract SimpleStorage {
  string public iden;

  function sendether () public payable {
    iden = "send ether called";
  }

  function recieveether() external payable {
    iden = "fallbak  got called";
  }

  function withdraw() public {
    address my = address(this);
    uint256 balance = my.balance;
    (msg.sender).transfer(balance);
  }
}
