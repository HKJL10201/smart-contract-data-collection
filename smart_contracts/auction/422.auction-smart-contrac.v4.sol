// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Auction {
    struct AuctionItem {
        string name;
        uint256 highestBid;
        address payable highestBidder;
        uint256 biddingEndTime;
        uint256 reservePrice;
        bool ended;
        mapping(address => uint256) bids;
        mapping(address => uint256) maxBids;
    }

    uint256 public endBlock;
    uint256 public totalItems;
    bool public escrowActive;
    address public escrow;
    mapping(uint256 => AuctionItem) public items;
    mapping(uint256 => uint256) public bidEndTimeExtensions;

    event AuctionCreated(uint256 indexed itemId, string name, uint256 reservePrice, uint256 biddingEndTime);
    event BidPlaced(uint256 indexed itemId, address indexed bidder, uint256 amount);
    event BidWithdrawn(uint256 indexed itemId, address indexed bidder, uint256 amount);
    event AuctionCancelled(uint256 indexed itemId);
    event AuctionEnded(uint256 indexed itemId, address indexed winner, uint256 amount);
    event BidRetracted(uint256 indexed itemId, address indexed bidder, uint256 amount);

    constructor(uint256 _endBlock) {
        require(_endBlock > block.number);
        endBlock = _endBlock;
    }

    modifier onlyBeforeEnd(uint256 itemId) {
        require(block.number < items[itemId].biddingEndTime + bidEndTimeExtensions[itemId], "Auction has ended");
        _;
    }

    modifier onlyAfterEnd(uint256 itemId) {
        require(block.number >= items[itemId].biddingEndTime + bidEndTimeExtensions[itemId], "Auction has not ended yet");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == escrow, "Only the owner can perform this action");
        _;
    }

    function createAuction(string memory name, uint256 reservePrice, uint256 biddingEndTime) public onlyOwner returns (uint256) {
        require(block.number < biddingEndTime);
        totalItems++;

        AuctionItem storage item = items[totalItems];
        item.name = name;
        item.highestBid = reservePrice;
        item.biddingEndTime = biddingEndTime;
        item.reservePrice = reservePrice;

        emit AuctionCreated(totalItems, name, reservePrice, biddingEndTime);

        return totalItems;
    }

    function placeBid(uint256 itemId, uint256 amount) public payable onlyBeforeEnd(itemId) {
        require(msg.sender != escrow, "The auction owner cannot bid on their own item");
        require(amount > items[itemId].highestBid, "The bid amount must be higher than the current highest bid");
        require(amount >= items[itemId].reservePrice, "The bid amount must be higher than or equal to the reserve price");

        AuctionItem storage item = items[itemId];
        uint256 currentMaxBid = item.maxBids[msg.sender];
        item.bids[msg.sender] = amount;
        item.maxBids[msg.sender] = currentMaxBid > amount ? currentMaxBid : amount;

        if (item.highestBidder == address(0)) {
            item.highestBid = amount;
            item.highestBidder = payable(msg.sender);
        } else if (amount > item.highestBid) {
            item.highestBid = amount;
            item.highestBidder = payable(msg.sender);
        }

        emit BidPlaced(itemId, msg.sender, amount);
    }

    function withdrawBid(uint256 itemId) public onlyBeforeEnd(itemId) {
        AuctionItem storage item = items[itemId];
        uint256 amount = item.bids[msg.sender];
        item.bids[msg.sender] = 0
            if (amount > 0) {
        if (amount == item.maxBids[msg.sender]) {
            item.maxBids[msg.sender] = 0;
        }
        payable(msg.sender).transfer(amount);
        emit BidWithdrawn(itemId, msg.sender, amount);
    }
}

function cancelAuction(uint256 itemId) public onlyOwner onlyBeforeEnd(itemId) {
    AuctionItem storage item = items[itemId];
    item.ended = true;

    emit AuctionCancelled(itemId);
}

function endAuction(uint256 itemId) public onlyOwner onlyAfterEnd(itemId) {
    AuctionItem storage item = items[itemId];
    require(!item.ended, "Auction has already ended");

    item.ended = true;
    address payable winner = item.highestBidder;
    uint256 amount = item.highestBid;
    escrow.transfer(amount);

    emit AuctionEnded(itemId, winner, amount);
}

function setEscrow(address _escrow) public onlyOwner {
    escrow = _escrow;
    escrowActive = true;
}

function extendBidTime(uint256 itemId, uint256 extraBlocks) public onlyOwner onlyBeforeEnd(itemId) {
    bidEndTimeExtensions[itemId] += extraBlocks;
}

function retractBid(uint256 itemId) public onlyBeforeEnd(itemId) {
    AuctionItem storage item = items[itemId];
    require(item.bids[msg.sender] > 0, "You have not placed a bid");

    uint256 amount = item.bids[msg.sender];
    item.bids[msg.sender] = 0;
    if (amount == item.maxBids[msg.sender]) {
        item.maxBids[msg.sender] = 0;
    }
    payable(msg.sender).transfer(amount);

    emit BidRetracted(itemId, msg.sender, amount);
}

function getBidAmount(uint256 itemId, address bidder) public view returns (uint256) {
    return items[itemId].bids[bidder];
}

function getMaxBidAmount(uint256 itemId, address bidder) public view returns (uint256) {
    return items[itemId].maxBids[bidder];
}

function getAuctionInfo(uint256 itemId) public view returns (
    string memory name,
    uint256 highestBid,
    address highestBidder,
    uint256 biddingEndTime,
    uint256 reservePrice,
    bool ended
) {
    AuctionItem memory item = items[itemId];
    name = item.name;
    highestBid = item.highestBid;
    highestBidder = item.highestBidder;
    biddingEndTime = item.biddingEndTime;
    reservePrice = item.reservePrice;
    ended = item.ended;
}
 }
 function getEscrowInfo() public view returns (
address escrowAddress,
bool active
) {
escrowAddress = escrow;
active = escrowActive;
}

function withdrawFromEscrow(uint256 amount) public {
require(msg.sender == escrow, "Only the escrow can withdraw from itself");
payable(msg.sender).transfer(amount); emit EscrowWithdrawn(amount); }

}
