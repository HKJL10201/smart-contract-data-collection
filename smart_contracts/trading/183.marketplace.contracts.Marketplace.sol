//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Token.sol";
import "./NFTCollection.sol";

error CannotBeZero();
error ItemNotOnSold();
error AuctionIsMissing();
error OnlySellerCancel();
error BidTooLow();
error AuctionEnded();
error AuctionIsActive();

contract Marketplace is Ownable, ERC721Holder {
    using SafeERC20 for IERC20;

    NFTCollection public nft;
    IERC20 public token;

    uint256 public period = 1 days;
    uint256 public minBids = 2;
    mapping(uint256 => Sale) private _sales;
    mapping(uint256 => Auction) private _auctions;

    struct Sale {
        address seller;
        uint256 price;
    }

    struct Auction {
        address seller;
        address bidder;
        uint256 bid;
        uint256 startTime;
        uint256 totalBids;
    }

     /** 
        @dev Events
     */

    event Cancel(address indexed seller, uint256 indexed tokenId);
    event Bid(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event SoldOut(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );
    event PlaceSellOrder(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price
    );

    event AuctionStarted(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 startTime
    );
    event AuctionFinished(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 finalPrice
    );
    event AuctionCancelled(uint256 indexed tokenId, address indexed seller);

    constructor() {
        token = new Token();
        nft = new NFTCollection();
    }

    /**
        @dev Config functions
        */

    /// @dev Set auction period
    function setAuctionPeriod(uint256 auctionPeriod) external onlyOwner {
        if (auctionPeriod == 0) revert CannotBeZero();
        period = auctionPeriod;
    }

    /// @dev Set min bids amount
    function setMinBids(uint256 _minBids) external onlyOwner {
        minBids = _minBids;
    }

    /// @dev Mint token
    function createItem(string memory uri) external {
        nft.safeMint(msg.sender, uri);
    }

    /**
        @dev Listing
     */

    /// @dev Place sell order on marketplace
    function listItem(uint256 tokenId, uint256 price) external {
        if (price == 0) revert CannotBeZero();
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        _sales[tokenId] = Sale(msg.sender, price);
        emit PlaceSellOrder(msg.sender, tokenId, price);
    }

    /// @dev Cancel token from marketplace
    function cancel(uint256 tokenId) external {
        if (_sales[tokenId].price == 0) revert ItemNotOnSold();
        if (_sales[tokenId].seller != msg.sender)
            revert OnlySellerCancel();
        delete _sales[tokenId];

        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        emit Cancel(msg.sender, tokenId);
    }

    /// @dev Buy token from marketplace
    function buyItem(uint256 tokenId) external {
        if (_sales[tokenId].price == 0) revert ItemNotOnSold();

        Sale memory sale = _sales[tokenId];
        delete _sales[tokenId];
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        token.safeTransferFrom(msg.sender, sale.seller, sale.price);

        emit SoldOut(tokenId, sale.seller, msg.sender, sale.price);
    }

    /// @dev Return current sale state info
    function saleInfo(uint256 tokenId) external view returns (Sale memory) {
        Sale memory _sale = _sales[tokenId];
        if (_sale.price == 0) revert ItemNotOnSold();
        return _sale;
    }

    /**
        @dev Auction
     */

    /// @dev List item on auction
    function listItemOnAuction(uint256 tokenId) external {
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        _auctions[tokenId] = Auction({
            seller: msg.sender,
            bidder: address(0),
            bid: 0,
            startTime: block.timestamp,
            totalBids: 0
        });
        emit AuctionStarted(tokenId, msg.sender, block.timestamp);
    }

    /// @dev Make bid for auction
    function makeBid(uint256 tokenId, uint256 price) external {
        Auction memory _auction = auctionInfo(tokenId);
        if (price <= _auction.bid) revert BidTooLow();
        if (block.timestamp >= _auction.startTime + period)
            revert AuctionEnded();
        if (_auction.bid > 0) {
            token.safeTransfer(_auction.bidder, _auction.bid);
        }

        token.safeTransferFrom(msg.sender, address(this), price);
        _auction.bid = price;
        _auction.bidder = msg.sender;
        _auction.totalBids++;
        _auctions[tokenId] = _auction;

        emit Bid(tokenId, msg.sender, price);
    }

    /// @dev Close auction
    function finishAuction(uint256 tokenId) external {
        Auction memory _auction = auctionInfo(tokenId);

        if (block.timestamp < _auction.startTime + period)
            revert AuctionIsActive();

        if (_auction.totalBids > minBids) {
            nft.safeTransferFrom(address(this), _auction.bidder, tokenId);
            token.safeTransfer(_auction.seller, _auction.bid);
            emit AuctionFinished(
                tokenId,
                _auction.seller,
                _auction.bidder,
                _auction.bid
            );
        } else {
            nft.safeTransferFrom(address(this), _auction.seller, tokenId);
            if (_auction.bidder != address(0)) {
                token.safeTransfer(_auction.bidder, _auction.bid);
            }
            emit AuctionCancelled(tokenId, _auction.seller);
        }
        delete _auctions[tokenId];
    }

    /// @dev Return current auction info
    function auctionInfo(uint256 tokenId) public view returns (Auction memory) {
        Auction memory _auction = _auctions[tokenId];
        if (_auction.seller == address(0)) revert AuctionIsMissing();
        return _auction;
    }
}
