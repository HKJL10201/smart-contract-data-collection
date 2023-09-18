pragma solidity ^0.4.2;

contract Auction {
  address public creator;
	address public highestBidder;
	uint public highestBid = 0;

  function Auction() {
    creator = msg.sender;
		highestBidder = msg.sender;
  }

	function getCreator() constant returns (address) {
		return creator;
	}

	function getHighestBidder() constant returns (address) {
		return highestBidder;
	}

	function addBid(uint newBid) returns (address) {
		if(newBid > highestBid) {
			highestBidder = msg.sender;
			highestBid = newBid;
		}
		return getHighestBidder();
	}

  function closeAuction() returns (address) {
    if (msg.sender == creator) {
      selfdestruct(creator);
    }
    revert();
  }
}