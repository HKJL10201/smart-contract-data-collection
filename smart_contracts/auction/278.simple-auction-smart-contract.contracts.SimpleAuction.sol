//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract SimpleAuction {
    uint256 public auctionEndTime;
    address payable public beneficiary;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) public pendingReturns;

    bool ended = false;

    event HighestBidIncrease(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    constructor(address payable _beneficiary, uint256 _biddingTime) {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid() public payable {
        //ensure auction time hasn't elapsed
        if (block.timestamp > auctionEndTime) {
            revert("Auction time elapsed");
        }

        //ensure current bid is higher than highest bid
        if (msg.value <= highestBid) {
            revert("There is a higher or equal bid");
        }

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit HighestBidIncrease(msg.sender, msg.value);
    }

    function withdraw() public returns (bool) {
        uint256 amount = pendingReturns[msg.sender];

        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd() public {
        //check if auction is still ongoing
        if (block.timestamp < auctionEndTime) {
            revert("Auction is still ongoing");
        }

        //check if auctionEnd function has been called
        if (ended) {
            revert("The function auctionEnded has already been called");
        }
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        beneficiary.transfer(highestBid);
    }
}
