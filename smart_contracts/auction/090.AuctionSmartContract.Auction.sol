pragma solidity ^0.6.1;
contract Auction {
  address public manager;
  address payable public seller;
  uint public latestBid;
  address payable public latestBidder;
 
  constructor() public {
    manager = msg.sender;
  }
 
  function auction(uint bid) public {
    latestBid = bid * 1 ether; 
    seller = msg.sender;
  }
 
  function bid() public payable {
    require(msg.value > latestBid);
 
    if (latestBidder != address(0)) {
      latestBidder.transfer(latestBid);
    }
    latestBidder = msg.sender;
    latestBid = msg.value;
  }
 
  function finishAuction() restricted public {
    seller.transfer(address(this).balance);
  }
 
  modifier restricted() {
    require(msg.sender == manager);
    _;
  }
}

//truffle compile
//truffle test
