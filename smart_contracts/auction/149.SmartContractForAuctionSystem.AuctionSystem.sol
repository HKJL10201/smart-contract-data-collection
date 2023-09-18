// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;



contract Auction {

    // Auction Owner
    address payable ownerofAuctioner;
    constructor(){
           ownerofAuctioner=payable(msg.sender);
           }

    //structure for bidder who bid for auction items
    struct Bid {
        address payable bidder;
        uint amount;
    }

    //structure for auuction attribut
    struct AuctionInfo {
        uint auctionId;
        string description;
        uint startTime;
        uint endTime;
        uint minBidValue;
        bool closed;
        uint bidCount;
        address payable highestBidder;
        uint highestBid;
        address[] bidders;
        Bid[] bids;
              
    }
    
   

    mapping(address => uint[]) public bidderAuctions;

    //special function for check before entering the function body and minimize the gas for execution of function
    modifier onlyOwner() {
    require(msg.sender == ownerofAuctioner, "Only the owner of this contract can call this function");
    _;
    }

     modifier notOnlyOwner() {
    require(msg.sender != ownerofAuctioner, "Owner can't call this smart contract function");
    _;
    }

    //event for if auction is created then emit from the create-auction function
    event NewAuction(uint auctionId, string description, uint startTime, uint endTime, uint minBidValue);
    //event for if someone bid for particular auction id
    event NewBid(uint auctionId, address bidder, uint amount);
    //event emit when auction time is complete for particullar auction id
    event AuctionEnded(uint auctionId, address winner, uint amount);
    


    //1) Create an Auction {AuctionID ,Description , Start Time , End Time , MinBidValue}
function createAuction(
        uint _auctionId,
         string memory _description,
          uint _startTime,
           uint _endTime,
            uint _minBidValue) 
            public {
        require(_startTime < _endTime, "End time must be greater than start time");
        AuctionInfo storage auction = auctions[_auctionId];
        auction.auctionId = _auctionId;
        auction.description = _description;
        auction.startTime = block.timestamp+_startTime;
        auction.endTime = block.timestamp+_endTime;
        auction.minBidValue = _minBidValue;
        auction.highestBidder = payable(address(0));
        auction.highestBid = 0;
        auction.closed=true;
        
        emit NewAuction(_auctionId, _description, _startTime, _endTime, _minBidValue);
    }
    //2) Place Bids On Active Auctions {AuctionID , BidValue} 
function bid(uint _auctionId,uint _bidValue)notOnlyOwner
          public payable {
        require(block.timestamp >= auctions[_auctionId].startTime, "Auction has not started yet");
        require(block.timestamp <= auctions[_auctionId].endTime, "Auction has already ended");
        require(_bidValue >= auctions[_auctionId].minBidValue, "Bid value must be greater than or equal to the minimum bid value");
        require(_bidValue > auctions[_auctionId].highestBid, "Bid value must be greater than current highest bid");
        require(auctions[_auctionId].closed==true, "Auction is closed");
        auctions[_auctionId].highestBidder = payable(msg.sender);
        auctions[_auctionId].highestBid = _bidValue;
        auctions[_auctionId].bidders.push(msg.sender);
        
        bidderAuctions[msg.sender].push(_auctionId);
        
        emit NewBid(_auctionId, msg.sender, _bidValue);
    }

    mapping(uint => AuctionInfo) public auctions;

    //3) Auction Owner can see list of All Bids Placed On their Auction.
function getAllBidsByAuctionOwner(uint _auctionId) public view onlyOwner returns (Bid[] memory) {
    AuctionInfo storage auction = auctions[_auctionId];
    return auction.bids;

    }


    //4) Bid Owners Can see list of all Auctions where they placed their Bids.
function getAllAuctionsByBidder(address _bidder) public view returns (uint[] memory) {
        uint[] memory auctionsByBidder = new uint[](bidderAuctions[_bidder].length);
        for (uint i = 0; i < bidderAuctions[_bidder].length; i++) {
            auctionsByBidder[i] = bidderAuctions[_bidder][i];
        }
        return auctionsByBidder;
    }

   
    //5) Auction Owner can select a bid and Mark the Auction status as Closed.
function closeAuction(uint _auctionId) public onlyOwner {
    AuctionInfo storage auction = auctions[_auctionId];
    require(auction.closed==true, "Auction is already closed");
    auction.closed = false;
  //  transfer(auction.highestBidder)';
   
    emit AuctionEnded(_auctionId, auction.highestBidder, auction.highestBid);

}

}
