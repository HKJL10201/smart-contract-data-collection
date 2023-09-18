// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SafePayment/SafePayment.sol";

contract NFTAuction is Ownable, Pausable, ReentrancyGuard, SafePayment {
    event AuctionCreated(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration
    );
    event AuctionBid(uint256 tokenId, uint256 bid, address bidder);
    event AuctionFinish(uint256 tokenId, uint256 price, address winner);
    event AuctionCancelled(uint256 tokenId);

    IERC721 public nftContract;
    uint256 private immutable _auctionFee;
    address private immutable _projectTreasury;
    mapping(uint256 => Auction) private _tokenIdAuction;

    struct Auction {
        uint128 startingPrice;
        uint128 endingPrice;
        uint64 duration;
        address seller;
        uint64 startedAt;
        address lastBidder;
        uint256 lastBid;
    }

    constructor(address projectTreasury, uint256 auctionFee) {
        require(auctionFee <= 10000, "auctionFee too high");
        _projectTreasury = projectTreasury;
        _auctionFee = auctionFee;
    }

    function setNFTContract(IERC721 nonFungibleContract) external onlyOwner {
        require(address(nftContract) == address(0), "NFT Contract already set");
        require(
            nonFungibleContract.supportsInterface(type(IERC721).interfaceId),
            "Non NFT contract"
        );
        nftContract = nonFungibleContract;
    }

    function _isAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    function _isAuctionOpen(Auction storage _auction)
        internal
        view
        returns (bool)
    {
        return (_auction.startedAt > 0 &&
            _auction.startedAt + _auction.duration > block.timestamp);
    }

    function _isAuctionFinish(Auction storage _auction)
        internal
        view
        returns (bool)
    {
        return (_auction.startedAt > 0 &&
            _auction.startedAt + _auction.duration <= block.timestamp);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function createAuction(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration
    ) external whenNotPaused {
        /* solhint-disable reason-string */
        // Check Overflow
        require(startingPrice == uint256(uint128(startingPrice)));
        require(endingPrice == uint256(uint128(endingPrice)));
        require(duration == uint256(uint64(duration)));
        require(endingPrice > startingPrice);
        require(duration >= 1 minutes);
        /* solhint-disable reason-string */
        require(_tokenIdAuction[tokenId].startedAt == 0, "Running Auction");

        address nftOwner = nftContract.ownerOf(tokenId);
        require(
            msg.sender == owner() || msg.sender == nftOwner,
            "Not Authorized"
        );

        // Escrow NFT
        nftContract.transferFrom(nftOwner, address(this), tokenId);

        Auction memory auction = Auction(
            uint128(startingPrice),
            uint128(endingPrice),
            uint64(duration),
            nftOwner,
            uint64(block.timestamp),
            address(0),
            0
        );
        _tokenIdAuction[tokenId] = auction;

        emit AuctionCreated(
            uint256(tokenId),
            uint256(auction.startingPrice),
            uint256(auction.endingPrice),
            uint256(auction.duration)
        );
    }

    function bid(uint256 tokenId) external payable whenNotPaused nonReentrant {
        Auction storage auction = _tokenIdAuction[tokenId];
        require(_isAuctionOpen(auction), "Auction not open");

        // TODO Close Auction on endingPrice reached
        require(auction.lastBid < auction.endingPrice, "endingPrice reached");

        require(msg.value > auction.startingPrice, "bid bellow min price");
        require(msg.value > auction.lastBid, "bid bellow last bid");
        // TODO control max bid
        // require(msg.value < auction.lastBid + maxBid, "bid too high");

        uint256 newBid = msg.value;
        if (newBid > auction.endingPrice) {
            safeSendETH(msg.sender, newBid - auction.endingPrice);
            newBid = auction.endingPrice;
        }

        if (auction.lastBid > 0) {
            safeSendETH(auction.lastBidder, auction.lastBid);
        }
        auction.lastBidder = msg.sender;
        auction.lastBid = newBid;

        emit AuctionBid(tokenId, newBid, msg.sender);
    }

    function cancelAuction(uint256 tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        Auction storage auction = _tokenIdAuction[tokenId];
        require(_isAuctionOpen(auction), "Auction not open");
        require(msg.sender == auction.seller, "Only seller can cancel");

        if (auction.lastBid > 0) {
            safeSendETH(auction.lastBidder, auction.lastBid);
        }
        nftContract.transferFrom(address(this), auction.seller, tokenId);

        delete _tokenIdAuction[tokenId];
        emit AuctionCancelled(tokenId);
    }

    function cancelAuctionWhenPaused(uint256 tokenId)
        external
        whenPaused
        onlyOwner
    {
        Auction storage auction = _tokenIdAuction[tokenId];
        require(_isAuction(auction), "Not Auction");

        if (auction.lastBid > 0) {
            safeSendETH(auction.lastBidder, auction.lastBid);
        }
        nftContract.transferFrom(address(this), auction.seller, tokenId);

        delete _tokenIdAuction[tokenId];
        emit AuctionCancelled(tokenId);
    }

    function finishAuction(uint256 tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        Auction storage auction = _tokenIdAuction[tokenId];
        require(
            _isAuctionFinish(auction) || auction.lastBid == auction.endingPrice,
            "Auction not finish"
        );

        if (auction.lastBid == 0) {
            nftContract.transferFrom(address(this), auction.seller, tokenId);
            emit AuctionFinish(tokenId, 0, auction.seller);
        } else {
            nftContract.transferFrom(
                address(this),
                auction.lastBidder,
                tokenId
            );
            uint256 treasuryFee = (auction.lastBid * _auctionFee) / 10000;
            uint256 sellerProceeds = auction.lastBid - treasuryFee;
            safeSendETH(_projectTreasury, treasuryFee);
            safeSendETH(auction.seller, sellerProceeds);
            emit AuctionFinish(tokenId, auction.lastBid, auction.lastBidder);
        }
        delete _tokenIdAuction[tokenId];
    }

    function withdrawUnclaimed(address to)
        external
        whenPaused
        onlyOwner
        returns (bool)
    {
        return getUnclaimed(to);
    }

    function getAuction(uint256 tokenId)
        external
        view
        returns (
            address seller,
            uint256 startingPrice,
            uint256 endingPrice,
            uint256 duration,
            uint256 startedAt,
            uint256 lastBid,
            address lastBidder
        )
    {
        Auction storage auction = _tokenIdAuction[tokenId];
        require(_isAuction(auction), "Not Auction");
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt,
            auction.lastBid,
            auction.lastBidder
        );
    }

    function getlastBid(uint256 tokenId) external view returns (uint256) {
        Auction storage auction = _tokenIdAuction[tokenId];
        require(_isAuction(auction), "Not Auction");
        return auction.lastBid;
    }
}
