// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Solirey.sol";

contract Auction1 is Solirey {
    struct AuctionInfo {
        address payable beneficiary;
        // Parameters of the auction. Times are either
        // absolute unix timestamps (seconds since 1970-01-01)
        // or time periods in seconds.
        uint auctionEndTime;
        uint startingBid;
        uint256 tokenId;
        // Current state of the auction.
        address highestBidder;
        uint highestBid;
        // Allowed withdrawals of previous bids
        mapping(address => uint) pendingReturns;
        // Set to true at the end, disallows any change.
        bool ended;
        bool transferred;
    }
    
    using Counters for Counters.Counter;

    // mapping from item ID to AuctionInfo
    mapping(uint => AuctionInfo) public _auctionInfo;

    // Events that will be emitted on changes.
    event AuctionCreated(uint indexed id , address indexed seller);
    event HighestBidIncreased(uint id, address bidder, uint amount);
    event AuctionEnded(uint id);

    function createAuction(uint _biddingTime, uint _startingBid) public {
        uid++;

        emit AuctionCreated(uid, msg.sender);

        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();
        _mint(address(this), newTokenId);

        _auctionInfo[uid].tokenId = newTokenId;
        _auctionInfo[uid].beneficiary = payable(msg.sender);
        _auctionInfo[uid].auctionEndTime = block.timestamp + _biddingTime;
        // _auctionInfo[uid].highestBidder = address(0);
        _auctionInfo[uid].startingBid = _startingBid;                        
    }
    
    function resell(uint _biddingTime, uint _startingBid, uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "Not authorized"
        );

        uid++;

        emit AuctionCreated(uid, msg.sender);
        
        transferFrom(msg.sender, address(this), tokenId);
        
        AuctionInfo storage ai = _auctionInfo[uid];
        ai.tokenId = tokenId;
        ai.beneficiary = payable(msg.sender);
        ai.auctionEndTime = block.timestamp + _biddingTime;
        ai.highestBidder = address(0);
        ai.startingBid = _startingBid;
    }
    
    function abort(uint id) public {
        AuctionInfo storage ai = _auctionInfo[id];
        
        require(
            msg.sender == ai.beneficiary, 
            "Not authorized"
        );
        
        require(
            ai.highestBidder == address(0),
            "Cannot abort"
        );
        
        require(
            ai.highestBid == 0,
            "Cannot abort"
        );
        
        require(
            block.timestamp <= ai.auctionEndTime,
            "Auction already ended"
        );
        
        require(
            ai.ended == false,
            "The auction has ended"
        );
        
        ai.ended = true;
        
        _transfer(address(this), ai.beneficiary, ai.tokenId);
    }

    /// Bid on the auction with the value sent
    /// The value will only be refunded if the auction is not won.
    function bid(uint id) public payable {
        AuctionInfo storage ai = _auctionInfo[id];

        require(
            block.timestamp <= ai.auctionEndTime,
            "Auction already ended"
        );

        // To prevent bidding on an aborted auction.
        require(
            ai.ended == false, 
            "Auction already ended"
        );

        require(
            msg.value > ai.highestBid,
            "Higher bid already exists"
        );
        
        require(
            msg.value > ai.startingBid,
            "The bid has to be higher than the specified starting bid"
        );

        if (ai.highestBid != 0) {
            ai.pendingReturns[ai.highestBidder] += ai.highestBid;
        }
        
        ai.highestBidder = msg.sender;
        ai.highestBid = msg.value;
        emit HighestBidIncreased(id, msg.sender, msg.value);
    }

    function withdraw(uint id) public returns (bool) {
        uint amount = _auctionInfo[id].pendingReturns[msg.sender];
        
        if (amount > 0) {
            _auctionInfo[id].pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                // No need to call throw here, just reset the amount owing
                _auctionInfo[id].pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd(uint id) public {
        AuctionInfo storage ai = _auctionInfo[id];
        
        require(block.timestamp >= ai.auctionEndTime, "Auction has not yet ended");
        require(ai.ended == false, "auctionEnd has already been called");

        ai.ended = true;
        
        if (ai.highestBidder != address(0)) {
            _transfer(address(this), ai.highestBidder, ai.tokenId);    
        }
        
        emit AuctionEnded(id);
    }
    
    function getTheHighestBid(uint id) public payable {
        AuctionInfo storage ai = _auctionInfo[id];
        
        require(block.timestamp >= ai.auctionEndTime, "Auction bidding time has not expired");
        require(msg.sender == ai.beneficiary, "You are not the beneficiary");
        require(ai.transferred == false, "Already transferred");
        require(ai.ended == true);
        
        ai.transferred = true;

        uint fee = ai.highestBid * 2 / 100;
        uint payment = ai.highestBid - (fee * 2);

        address artist = _artist[_auctionInfo[id].tokenId];
        payable(artist).transfer(fee);    

        admin.transfer(fee);
        ai.beneficiary.transfer(payment);
    }
    
    function getPendingReturn(uint id) external view returns (uint) {
        return _auctionInfo[id].pendingReturns[msg.sender];
    }

        // for testing only 
    function getAdmin() external view returns (address) {
        return admin;
    }

    function getAuctionInfo(uint id) external view returns (address beneficiary, uint auctionEndTime, uint startingBid, uint256 tokenId, address highestBidder, uint highestBid, bool ended) {
        return (_auctionInfo[id].beneficiary, _auctionInfo[id].auctionEndTime, _auctionInfo[id].startingBid, _auctionInfo[id].tokenId, _auctionInfo[id].highestBidder, _auctionInfo[id].highestBid, _auctionInfo[id].ended);
    }
}
 