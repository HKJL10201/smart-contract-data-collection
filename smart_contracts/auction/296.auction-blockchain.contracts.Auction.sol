pragma solidity ^0.4.19;
contract Auction {
  address public manager;
  address public seller;
  uint public latestBid;
  address public latestBidder;

  constructor() public {
    manager = msg.sender;
  }

  function auction(uint bid) public {
    require(latestBid == 0, "There is an ongoing auction. Wait until it is finished");
    latestBid = bid * 1 ether; //bid is calculated in wei
    seller = msg.sender;
  }

  function bid() public payable {
    require(msg.value > latestBid);
 
    if (latestBidder != 0x0) {
      latestBidder.transfer(latestBid);
    }
    latestBidder = msg.sender;
    latestBid = msg.value;
  }

  function finishAuction() restricted public {
    seller.transfer(address(this).balance);
    latestBid = 0;
  }

  modifier restricted() {
    require(msg.sender == manager);
    _;
  }
}