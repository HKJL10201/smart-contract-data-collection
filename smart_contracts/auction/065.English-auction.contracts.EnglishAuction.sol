// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract EnglishAuction {
  string public product;
  uint public price;
  address public owner;
  address public buyer;

  constructor(string memory _product, uint _price) {
      product = _product;
      price = _price;
      owner = msg.sender;
    }

  function Bid(uint bid) external payable returns (string memory isExecuted){
      require(bid < price, "Not a high enough bid");
      require(bid > address(this).balance, "Not enough money to bid");
      return("Your bid is accepted");
  }
}