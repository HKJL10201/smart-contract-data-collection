// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Auction {
    address public seller;
    uint public latestBid;
    address public latestBidder;
    enum State {Started, Ended}
    State public auctionState;

    constructor(uint startingPriceWei) {
        seller = msg.sender;
        latestBid = startingPriceWei;
        auctionState = State.Started;
    }

    function bid() public payable notOwner {
        // should revert if funds sent are not greater than last bid
        require(
            msg.value > latestBid,
            "Bid must be greater than last bid"
        );
        // should revert if auction is already finished
        require(
            auctionState != State.Ended,
            "Auction is already finished"
        );
        uint previousBid = latestBid;
        address previousBidder = latestBidder;
        // should update latestBidder, latestBid fields
        latestBidder = msg.sender;
        latestBid = msg.value;

        // should return previous bid to the bidder
        if (previousBidder != address(0)) {
            payable(previousBidder).transfer(previousBid);
        }
    }

    function finishAuction() public onlyOwner {
        require(
            auctionState != State.Ended,
            "Auction is already finished"
        );
        auctionState = State.Ended;
        // should withdraw winning bid to the seller
        payable(seller).transfer(latestBid);
    }

    modifier notOwner(){
        require(msg.sender != seller);
        _;
    }
    
    modifier onlyOwner(){
        require(msg.sender == seller);
        _;
    }
}
