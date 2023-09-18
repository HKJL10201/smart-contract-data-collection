// SPDX-License-Identifier: MIT
pragma solidity > 0.7.0 <= 0.9.0;

contract Auction {

    address payable public beneficiary;    // Here the beneficiary means the auctioneer
    uint public auctionEndTime;


    // Current state of the auction
    address public highestBidder;
    uint public highestBid;
    bool ended;


    mapping(address => uint) pendingReturns;


    event highestBidIncreased(address bidder, uint amount);
    event auctionEnding(address winner, uint amount);

    constructor(uint _biddingTime, address payable _beneficiary) {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid() public payable {
        if(block.timestamp > auctionEndTime) revert("The auction has ended!");

        if(msg.value < highestBid) revert("Bid is not high enough!");

        if(highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit highestBidIncreased(msg.sender, msg.value);
        
    }

    // Withdraw bids that are overbid

    function withdraw() public payable returns(bool) {
        uint amount = pendingReturns[msg.sender];
        if(amount > 0) {
            pendingReturns[msg.sender] = 0;
        }

        if(!payable(msg.sender).send(amount)) {
            pendingReturns[msg.sender] = amount;
        }
        return true;
    }

    function auctionEnd() public {

        if(block.timestamp < auctionEndTime) revert("The auction has not yet ended.");
        if(ended) revert("The auction is already over!");

        ended = true;
        emit auctionEnding(highestBidder, highestBid);
        beneficiary.transfer(highestBid);
    }
}
