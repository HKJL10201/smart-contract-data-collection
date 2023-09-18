// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Solirey.sol";

contract Auction is IERC721Receiver {
    Solirey solirey;

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

    // mapping from item ID to AuctionInfo
    mapping(uint => AuctionInfo) public _auctionInfo;

    // Events that will be emitted on changes.
    event AuctionCreated(uint indexed id , address indexed seller);
    event HighestBidIncreased(uint id, address bidder, uint amount);
    event AuctionEnded(uint id);

    constructor(address solireyAddress) {
        solirey = Solirey(solireyAddress);
    }

    function createAuction(uint _biddingTime, uint _startingBid) external {
        solirey.incrementUid();
        uint256 uid = solirey.currentUid();

        emit AuctionCreated(uid, msg.sender);

        solirey.incrementToken();

        uint256 tokenId = solirey.currentToken();
        solirey.mint(address(this), tokenId);

        solirey.updateArtist(uid, msg.sender);

        _auctionInfo[uid].tokenId = tokenId;
        _auctionInfo[uid].beneficiary = payable(msg.sender);
        _auctionInfo[uid].auctionEndTime = block.timestamp + _biddingTime;
        _auctionInfo[uid].startingBid = _startingBid;                        
    }
    
    function abort(uint id) external {
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
        
        _auctionInfo[id].ended = true;
        solirey.transferFrom(address(this), ai.beneficiary, ai.tokenId);
    }

    /// Bid on the auction with the value sent
    /// The value will only be refunded if the auction is not won.
    function bid(uint id) external payable {
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
        
        _auctionInfo[id].highestBidder = msg.sender;
        _auctionInfo[id].highestBid = msg.value;

        emit HighestBidIncreased(id, msg.sender, msg.value);
    }

    function withdraw(uint id) external returns (bool) {
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

    function auctionEnd(uint id) external {
        AuctionInfo storage ai = _auctionInfo[id];
        
        require(block.timestamp >= ai.auctionEndTime, "Auction has not yet ended");
        require(ai.ended == false, "Already ended");

        _auctionInfo[id].ended = true;
        
        if (ai.highestBidder != address(0)) {
            solirey.transferFrom(address(this), ai.highestBidder, ai.tokenId);    
        } else {
            solirey.transferFrom(address(this), ai.beneficiary, ai.tokenId);    
        }
        
        emit AuctionEnded(id);
    }
    
    function getTheHighestBid(uint id) external payable {
        AuctionInfo storage ai = _auctionInfo[id];
        
        require(block.timestamp >= ai.auctionEndTime, "Auction bidding time has not expired");
        require(msg.sender == ai.beneficiary, "You are not the beneficiary");
        require(ai.transferred == false, "Already transferred");
        require(ai.ended == true);
        
        _auctionInfo[id].transferred = true;

        uint fee = ai.highestBid * 2 / 100;
        uint payment = ai.highestBid - fee - fee;

        address artist = solirey._artist(_auctionInfo[id].tokenId);
        payable(artist).transfer(fee);    
        solirey.admin().transfer(fee);
        ai.beneficiary.transfer(payment);
    }
    
    function getPendingReturn(uint id) external view returns (uint) {
        return _auctionInfo[id].pendingReturns[msg.sender];
    }

    function onERC721Received(address _from, address, uint256 _tokenId, bytes calldata _data) public virtual override returns (bytes4) {
        // require(
        //     solirey.ownerOf(_tokenId) == msg.sender,
        //     "Not authorized"
        // );

        (uint _biddingTime, uint _startingBid) = abi.decode(_data, (uint, uint));  

        solirey.incrementUid();
        uint256 uid = solirey.currentUid();

        emit AuctionCreated(uid, _from);
                
        AuctionInfo storage ai = _auctionInfo[uid];
        ai.tokenId = _tokenId;
        ai.beneficiary = payable(_from);
        ai.auctionEndTime = block.timestamp + _biddingTime;
        ai.highestBidder = address(0);
        ai.startingBid = _startingBid;
        
        return this.onERC721Received.selector;
    }

    // for testing only 
    function getAdmin() external view returns (address) {
        return solirey.admin();
    }

    function getAuctionInfo(uint id) external view returns (address beneficiary, uint auctionEndTime, uint startingBid, uint256 tokenId, address highestBidder, uint highestBid, bool ended) {
        return (_auctionInfo[id].beneficiary, _auctionInfo[id].auctionEndTime, _auctionInfo[id].startingBid, _auctionInfo[id].tokenId, _auctionInfo[id].highestBidder, _auctionInfo[id].highestBid, _auctionInfo[id].ended);
    }
}