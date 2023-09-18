// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AuctionPlatform is Ownable {
    address public PlatformOwner;

    struct Bidder {
        uint id;
        address bidderAdress;
    }

    enum State { Open, Closed, Cancelled, Dispute }

    struct Auction {
        string name;
        uint price;
        uint endTime;
        Bidder highestBidder;
        address auctioneer;
        uint bidMinimumIncrement;
        State state;
    }

    

    Bidder[] bidders;
    Auction[] auctions;

    mapping(address => Bidder) bidderAdr;

    event AuctionCreated(uint indexed auctionId, string itemname, uint startingPrice, uint auctionEndTime);
    event AuctionCancelled(uint indexed auctionId);
    event bidPlaced(uint indexed auctionId, uint bidAmount, address bidder);

    constructor() payable{
        PlatformOwner = msg.sender;
    }

    function startAuction (string memory _name, uint _price, uint _endTime, uint _bidMinimumIncrement) public {
        require(_endTime > block.timestamp, "Auction end time must be in the future");
        require(_endTime - block.timestamp > 86400, "Auction should run minimum of 1 day");

        Auction memory newAuction = Auction({
            name: _name,
            price: _price,
            endTime: _endTime,
            highestBidder: Bidder({
                id: 0,
                bidderAdress: address(0)
            }),
            auctioneer: msg.sender,
            bidMinimumIncrement: _bidMinimumIncrement,
            state: State.Open
        });

        auctions.push(newAuction);
        uint auctionId = auctions.length - 1;

        emit AuctionCreated(auctionId, _name, _price, _endTime);
    }

    function bid (uint _auctionId, uint _bidAmount) public payable {
        Auction storage auction = auctions[_auctionId];
        require(auction.endTime > block.timestamp, "Auction end time has passed");
        require(auction.state == State.Open, "Auction is not open");
        require(_bidAmount > auction.price, "Bid amount should be greater than the starting price");
        require(_bidAmount - auction.price > auction.bidMinimumIncrement, "Bid amount should be greater than the minimum increment");

        if (auction.highestBidder.id != 0) {
            payable(auction.highestBidder.bidderAdress).transfer(auction.price);
        }

        auction.price = _bidAmount;
        auction.highestBidder = Bidder({
            id: bidders.length,
            bidderAdress: msg.sender
        });

        emit bidPlaced(_auctionId, _bidAmount, msg.sender);
    }

    function cancelAuction (uint _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == State.Open, "Auction is not open");
        require(msg.sender == auction.auctioneer || msg.sender == owner(), "Only the owner or the auctioneer can cancel the auction");

        auction.state = State.Cancelled;
        payable(auction.highestBidder.bidderAdress).transfer(auction.price);

        emit AuctionCancelled(_auctionId);
    }

    function endAuction (uint _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        require(auction.endTime < block.timestamp, "Auction end time has not passed");
        require(auction.state == State.Open, "Auction is not open");
        require(msg.sender == owner(), "Only the owner can end the auction");

        auction.state = State.Closed;
    }

    function getAuctionDetails (uint _auctionId) public view returns (string memory, uint, uint, uint, address, uint, State) {
        Auction storage auction = auctions[_auctionId];
        return (auction.name, auction.price, auction.endTime, auction.highestBidder.id, auction.highestBidder.bidderAdress, auction.bidMinimumIncrement, auction.state);
    }

    function getBidderDetails (uint _bidderId) public view returns (uint, address) {
        Bidder storage bidder = bidders[_bidderId];
        return (bidder.id, bidder.bidderAdress);
    }

    function getAuctionCount () public view returns (uint) {
        return auctions.length;
    }

    function getBiddersForAuction (uint _auctionId) public view returns (Bidder[] memory) {
        Auction storage auction = auctions[_auctionId];
        Bidder[] memory biddersForAuction = new Bidder[](auction.highestBidder.id + 1);
        for (uint i = 0; i <= auction.highestBidder.id; i++) {
            biddersForAuction[i] = bidders[i];
        }
        return biddersForAuction;
    }

    function getOpenAuctions () public view returns (Auction[] memory) {
        Auction[] memory openAuctions = new Auction[](auctions.length);
        uint openAuctionCount = 0;
        for (uint i = 0; i < auctions.length; i++) {
            if (auctions[i].state == State.Open) {
                openAuctions[openAuctionCount] = auctions[i];
                openAuctionCount++;
            }
        }
        return openAuctions;
    }

    /* TODO:
     Set the rules for Awarding the money to the auctioneer
     The item in the auction should be delivered to the highest bidder within 7 days of the auction end time
     The Auctioneer and the highest bidder should both agree that the item has been delivered within 7 days of the auction end time before the money is awarded to the auctioneer
     If the item is not delivered within 7 days of the auction end time, the money should be refunded to the highest bidder
     If the item is delivered as per the auctioneer, and the highest bidder does not agree that the item has been delivered, the money should stay on the contract and the auctioneer can mark the auction with a dispute
     If the auctioneer marks the auction with a dispute, the owner of the contract should be able to resolve the dispute and award the money to the auctioneer or the highest bidder
    */

    function awardMoneyToAuctioneer (uint _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == State.Closed, "Auction is not closed");
        require(msg.sender == owner(), "Only the owner can award the money to the auctioneer");

        payable(auction.auctioneer).transfer(auction.price);
    }

    function refundMoneyToHighestBidder (uint _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == State.Closed, "Auction is not closed");
        require(msg.sender == owner(), "Only the owner can refund the money to the highest bidder");

        payable(auction.highestBidder.bidderAdress).transfer(auction.price);
    }

    function markAuctionWithDispute (uint _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == State.Closed, "Auction is not closed");
        require(msg.sender == auction.auctioneer, "Only the auctioneer can mark the auction with a dispute");

        auction.state = State.Dispute;
    }

    function resolveDisputeAndAwardMoneyToAuctioneer (uint _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == State.Dispute, "Auction is not in dispute");
        require(msg.sender == owner(), "Only the owner can resolve the dispute and award the money to the auctioneer");

        auction.state = State.Closed;
        payable(auction.auctioneer).transfer(auction.price);
    }

    function resolveDisputeAndRefundMoneyToHighestBidder (uint _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == State.Dispute, "Auction is not in dispute");
        require(msg.sender == owner(), "Only the owner can resolve the dispute and refund the money to the highest bidder");

        auction.state = State.Closed;
        payable(auction.highestBidder.bidderAdress).transfer(auction.price);
    }
}