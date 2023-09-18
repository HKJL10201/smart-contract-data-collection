// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Auction {
    address payable public beneficiary;
    uint256 public auctionEndTime;
    uint256 public highestBid;
    address public highestBidder;
    bool ended = false;
    mapping(address => uint256) public pendingReturns;

    event highestBidIncrease(address bidder, uint256 amount);
    event auctionEnded(address winner, uint256 amount);

    constructor(uint256 _biddingTime, address payable _beneficiary) {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid() public payable {
        if (block.timestamp < auctionEndTime) {
            revert("Auction End");
        }
        if (msg.value <= highestBid) {
            revert("Your price is lower than the highest bid");
        }
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit highestBidIncrease(msg.sender, msg.value);
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
        if (ended) {
            revert("Auction end");
        }
        if (block.timestamp < auctionEndTime) {
            revert("Auction not end");
        }
        ended = true;
        emit auctionEnded(highestBidder, highestBid);

        beneficiary.transfer(highestBid);
    }
}
