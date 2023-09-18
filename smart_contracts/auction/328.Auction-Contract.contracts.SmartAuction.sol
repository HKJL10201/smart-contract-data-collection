// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
    @title Smart Contract Auction Contract
    @dev Implementation of a simple auction on the Ethereum chain

**/

contract smartAuction {
    address payable public beneficiary;
    uint public auctionEnd;

    address payable public highestBidder;
    uint public highestBid;

    mapping(address => uint)pendingReturns;

    bool ended;
    event HighestbidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(uint _biddingTime) {
          beneficiary = payable(msg.sender);
        auctionEnd = block.timestamp + _biddingTime;
    }

    function bid() public payable {
        require(block.timestamp <= auctionEnd, "Auction already over");
        require(msg.value > highestBid, "There is already a higher bid");

        if( highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = payable(msg.sender);

        emit HighestbidIncreased(msg.sender, msg.value);
    }

    function withdraw() public returns(bool) {
        uint amount = pendingReturns[msg.sender];
        if(amount > 0) {
            pendingReturns[msg.sender] = 0;

            if(!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }

        return true;
    
    }


    function endAuction() public {
        require(block.timestamp >= auctionEnd, "Auction not yet ended");
        require(!ended, "auctionEnd was called");

        ended = true;

        beneficiary.transfer(highestBid);
        emit AuctionEnded(highestBidder, highestBid);
    }

    function auctionAlreadyEnded() public view returns(bool) {
        return ended;
    }

}


