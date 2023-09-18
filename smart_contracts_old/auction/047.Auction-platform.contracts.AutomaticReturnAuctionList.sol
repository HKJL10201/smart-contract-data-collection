pragma solidity ^0.5.0;

import "./AuctionList.sol";

contract AutomaticReturnAuctionList is AuctionList {

    constructor() public {}

    mapping(uint => Bid[]) public auctionIdsToBids;
    mapping(uint => uint) public numberOfBids;

    function makeBid(uint auctionID, uint256 bidPrice) public payable auctionLive(auctionID) returns(bool){
        require(bidPrice >= auctions[auctionID].highestBid + SMALLEST_TICK_IN_WEI, "Bid too low!");
        require(bidPrice >= auctions[auctionID].startPrice + SMALLEST_TICK_IN_WEI, "Bid too low!");
        (,uint256 sumOfPreviousBids) = getSumOfPreviousBids(auctionID);
        uint256 overallBid = msg.value + sumOfPreviousBids;
        require(overallBid >= bidPrice, "Wrong message value!");

        auctions[auctionID].highestBid = overallBid;
        auctions[auctionID].highestBidAddress = msg.sender;

        updateBid(msg.sender, overallBid, auctionID);

        emit BidDone(auctionID, overallBid, msg.sender);

        return true;
    }

    function endAuction(uint auctionID) public payable auctionFinished(auctionID) {
        Auction storage endedAuction = auctions[auctionID];
        if (endedAuction.ended) {
            return;
        }

        endedAuction.ended = true;

        payBidToLosers(endedAuction);
        sendWinningBidToOwner(endedAuction);

        addAuctionToDeleted(endedAuction);
        deleteAuction(auctionID);

        emit AuctionEnded(endedAuction.id, endedAuction.highestBid, endedAuction.highestBidAddress);
    }

    function payBidToLosers(Auction memory endedAuction) private {
        address winnerAddress = endedAuction.highestBidAddress;
        uint256 winningBid = endedAuction.highestBid;

        for(uint256 i = 0; i < numberOfBids[endedAuction.id]; i++){
            Bid memory current = auctionIdsToBids[endedAuction.id][i];
            if(current.BidAddress == winnerAddress && current.bidPrice == winningBid){
                continue;
            }

            current.BidAddress.transfer(current.bidPrice);
        }
    }

    function deleteAuction(uint auctionID) private {
        auctions[auctionID] = auctions[auctionNumber];
        auctionIdsToBids[auctionID] = auctionIdsToBids[auctionNumber];
        numberOfBids[auctionID] = numberOfBids[auctionNumber];

        auctions[auctionID].id = auctionID;

        delete auctions[auctionNumber];
        delete auctionIdsToBids[auctionNumber];
        delete numberOfBids[auctionNumber];

        auctionNumber --;
    }

    function getSumOfPreviousBids(uint auctionID) public view returns(uint, uint256){
        uint256 sum = 0;
        address bidder = msg.sender;
        for(uint256 i = 0; i < numberOfBids[auctionID]; i++){
            Bid memory current = auctionIdsToBids[auctionID][i];
            if(current.BidAddress == bidder){
                sum += current.bidPrice;
            }
        }

        return (auctionID, sum);
    }

    function updateBid(address payable bidder, uint256 value, uint auctionID) private {
        bool exists = false;

        for(uint256 i = 0; i < numberOfBids[auctionID]; i++){
            Bid storage current = auctionIdsToBids[auctionID][i];
            if(current.BidAddress == bidder){
                current.bidPrice = value;
                exists = true;
                break;
            }
        }

        if(!exists) {
            numberOfBids[auctionID] ++;
            auctionIdsToBids[auctionID].push(Bid(value, bidder));
        }
    }
}