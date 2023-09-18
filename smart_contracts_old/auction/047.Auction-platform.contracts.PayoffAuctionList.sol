pragma solidity ^0.5.0;

import "./AuctionList.sol";

contract PayoffAuctionList is AuctionList {

    constructor() public {}

    mapping(address => uint256) public payoffs;

    function makeBid(uint auctionID, uint256 bidPrice) public payable auctionLive(auctionID) returns (bool) {
        require(bidPrice >= auctions[auctionID].highestBid + SMALLEST_TICK_IN_WEI, "Bid too low!");
        require(bidPrice >= auctions[auctionID].startPrice + SMALLEST_TICK_IN_WEI, "Bid too low!");
        require(msg.value + getPayoffsWithBid(auctionID) >= bidPrice, "Wrong message value!");

        address prevHighestBidderAddress = auctions[auctionID].highestBidAddress;
        uint256 prevHighestBid = auctions[auctionID].highestBid;

        payoffs[prevHighestBidderAddress] += prevHighestBid;

        auctions[auctionID].highestBid = bidPrice;
        auctions[auctionID].highestBidAddress = msg.sender;

        if(payoffs[msg.sender] >= bidPrice) {
            payoffs[msg.sender] -= bidPrice;
        }
        else {
            payoffs[msg.sender] = 0;
        }

        emit BidDone(auctionID, auctions[auctionID].highestBid, auctions[auctionID].highestBidAddress);
        return true;
    }

    function endAuction(uint auctionID) public payable auctionFinished(auctionID) {
        Auction storage endedAuction = auctions[auctionID];
        if (endedAuction.ended) {
            return;
        }

        endedAuction.ended = true;

        sendWinningBidToOwner(endedAuction);
        addAuctionToDeleted(endedAuction);
        deleteAuction(auctionID);

        emit AuctionEnded(endedAuction.id, endedAuction.highestBid, endedAuction.highestBidAddress);
    }

    function deleteAuction(uint auctionID) private {
        auctions[auctionID] = auctions[auctionNumber];
        auctions[auctionID].id = auctionID;

        delete auctions[auctionNumber];
        auctionNumber --;
    }

    function getPayoffsWithBid(uint auctionId) public view returns (uint256) {
        uint256 result = payoffs[msg.sender];
        if (msg.sender == auctions[auctionId].highestBidAddress)
            result += auctions[auctionId].highestBid;

        return result;
    }

    function getPayoff(address adr) public view returns (address, uint256) {
        return (adr, payoffs[adr]);
    }

    function returnPayoffs() public {
        uint payoff = payoffs[msg.sender];
        if (payoff == 0)
            return;

        payoffs[msg.sender] = 0;
        address payable payoffOwner = msg.sender;
        payoffOwner.transfer(payoff);
    }
}