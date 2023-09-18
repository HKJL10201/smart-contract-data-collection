// SPDX-License-Identifier: MIT

import "hardhat/console.sol";
pragma solidity 0.8.19;

contract Auction {
  struct Product {
    uint productId;
    string name;
    uint price;
    address owner;
    uint auctionTime;
    bool isAuction;
    bool isProductRegistered;
    mapping(address => uint) bids;
  }
  struct User {
    string name;
    address addr;
    bool isUserRegistered;
  }

  address public owner;
  uint public productCounter;
  uint public userCounter;

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can register a product");
    _;
  }

  mapping(uint => Product) public products;
  mapping(uint => User) public users;

  constructor() {
    owner = msg.sender;
  }

  function productRegister(string memory _name) public onlyOwner {
    products[productCounter].productId = productCounter;
    products[productCounter].name = _name;
    products[productCounter].price = 0;
    products[productCounter].owner = msg.sender;
    products[productCounter].auctionTime = 0;
    products[productCounter].isAuction = false;
    products[productCounter].isProductRegistered = true;
    productCounter++;
  }

  function userRegister(string memory _name) public {
    users[userCounter] = User(_name, msg.sender, true);
  }

  function startAuction(
    uint _ID,
    uint _price,
    uint _auctionTime
  ) public onlyOwner {
    Product storage prd = products[_ID];
    require(!prd.isAuction, "This product is already in an auction state");
    prd.price = _price;
    prd.auctionTime = block.timestamp + _auctionTime;
    prd.isAuction = true;
  }

  function bid(uint _userID, uint _productID, uint _price) public payable {
    User storage usr = users[_userID];
    Product storage prd = products[_productID];

    require(
      usr.isUserRegistered && prd.isProductRegistered,
      "User or product is not registered"
    );
    require(prd.isAuction, "This product is not up for auction");
    require(block.timestamp < prd.auctionTime, "Auction has ended");

    require(
      _price > prd.bids[prd.owner],
      "Bid amount should be higher than the current highest bid"
    );

    address previousHighestBidder = prd.owner;
    uint previousHighestBid = prd.bids[prd.owner];
    prd.bids[prd.owner] = 0;
    (bool success, ) = previousHighestBidder.call{ value: previousHighestBid }(
      ""
    );
    require(success, "Refund failed");
    prd.owner = usr.addr;
    prd.bids[usr.addr] = _price;
  }

  function withdrawBid(uint _productID) public {
    Product storage prd = products[_productID];
    uint bidAmount = prd.bids[msg.sender];
    require(bidAmount > 0, "No bid found for this product");
    // require(block.timestamp < prd.auctionTime, "Auction has ended");
    prd.bids[msg.sender] = 0;
    (bool success, ) = msg.sender.call{ value: bidAmount }("");
    require(success, "Withdrawal failed");
  }

  function getHighestBid(uint _productID) public view returns (uint) {
    return products[_productID].bids[products[_productID].owner];
  }
}
