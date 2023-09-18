//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Wallet {

  address payable public owner;

  constructor() {
      owner = payable(msg.sender);
  }

  receive() external payable {}

  function withdraw(uint _amount) external {
     require(msg.sender == owner, "Sorry, you are not the owner, withdrawal denied");
      payable(msg.sender).transfer(_amount);
  }

  function getBalance() public view returns (uint) {
      return address(this).balance;
  }
}