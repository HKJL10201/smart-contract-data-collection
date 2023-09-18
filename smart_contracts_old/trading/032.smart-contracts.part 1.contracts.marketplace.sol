// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MyNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public contractAddress;

    constructor(address marketplaceAddress)
        ERC721("Property Marketplace", "PMP")
    {
        contractAddress = marketplaceAddress;
    }

    function createToken(address owner, string memory tokenURI)
        public
        returns (uint256)
    {
        require(msg.sender == contractAddress, "Only marketplace can mint");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(owner, newItemId);
        _setTokenURI(newItemId, tokenURI);
        return newItemId;
    }
}

contract PropertyMarketplace is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    uint256 private auctionDuration;
    Counters.Counter private _itemIds;
    IERC20 public token;
    MyNFT public nft;

    mapping(uint256 => ListedItem) private _itemsListed;

    struct ListedItem {
        bool onAuction;
        uint256 itemId;
        uint256 price;
        uint256 lastBid;
        uint256 bidsCount;
        uint256 auctionStartTime;
        address owner;
        address lastBidder;
    }

    constructor(address _tokenContract) {
        auctionDuration = 3;
        token = IERC20(_tokenContract);
    }

    function setNftContract(address _nftContract) external onlyOwner {
        nft = MyNFT(_nftContract);
    }

    function getMarketItem(uint256 marketItemId)
        public
        view
        returns (
            uint256 _itemId,
            uint256 _price,
            uint256 _lastBid,
            uint256 _auctionStartTime
        )
    {
        return (
            _itemsListed[marketItemId].itemId,
            _itemsListed[marketItemId].price,
            _itemsListed[marketItemId].lastBid,
            _itemsListed[marketItemId].auctionStartTime
        );
    }

    function getAuctionDuration() external view returns (uint256) {
        return auctionDuration;
    }

    function setAuctionDuration(uint256 newAuctionDuration) external onlyOwner {
        auctionDuration = newAuctionDuration;
    }

    function createItem(string memory _tokenURI) external returns (uint256) {
        uint256 newItemId = nft.createToken(msg.sender, _tokenURI);
        return newItemId;
    }

    function listItem(uint256 _tokenId, uint256 _price) external {
        // require(_itemsListed[_tokenId].itemId == 0, "Item is already listed");
        require(
            nft.ownerOf(_tokenId) == msg.sender,
            "Item does not exist or you are not the owner"
        );

        if (_itemsListed[_tokenId].itemId == 0) {
            _itemsListed[_tokenId].itemId = _tokenId;
            _itemsListed[_tokenId].price = _price;
            _itemsListed[_tokenId].owner = msg.sender;
        } else {
            _itemsListed[_tokenId].price = _price;
        }

        emit Listed(msg.sender, _tokenId, _price);
    }

    function buyItem(uint256 _tokenId) external nonReentrant {
        require(_itemsListed[_tokenId].itemId != 0, "Buying non-existing item");
        require(
            _itemsListed[_tokenId].onAuction == false,
            "The item is on auction"
        );

        address owner = _itemsListed[_tokenId].owner;
        token.transferFrom(msg.sender, owner, _itemsListed[_tokenId].price);
        nft.transferFrom(owner, msg.sender, _tokenId);
        _itemsListed[_tokenId].owner = msg.sender;

        emit Sold(owner, msg.sender, _tokenId, _itemsListed[_tokenId].price);
    }

    function cancelListing(uint256 _tokenId) external {
        require(
            _itemsListed[_tokenId].itemId != 0,
            "Cancelling not listed item"
        );
        require(
            _itemsListed[_tokenId].owner == msg.sender,
            "Only owner can cancel listing"
        );
        delete _itemsListed[_tokenId];

        emit Unlisted(msg.sender, _tokenId);
    }

    function listItemOnAuction(uint256 _tokenId, uint256 _startingPrice)
        external
        nonReentrant
    {
        require(
            nft.ownerOf(_tokenId) == msg.sender,
            "Only owner can list item on auction"
        );

        if (_itemsListed[_tokenId].owner == address(0)) {
            _itemsListed[_tokenId].owner = msg.sender;
            _itemsListed[_tokenId].itemId = _tokenId;
        }

        _itemsListed[_tokenId].price = _startingPrice;
        _itemsListed[_tokenId].auctionStartTime = block.timestamp;
        _itemsListed[_tokenId].onAuction = true;

        emit SetOnAuction(msg.sender, _tokenId, _startingPrice);
    }

    function makeBid(uint256 _tokenId, uint256 _amount) public nonReentrant {
        require(
            _itemsListed[_tokenId].onAuction == true,
            "Bidding on item out of auction"
        );
        require(_amount > _itemsListed[_tokenId].lastBid, "Bid is too low");

        if (_itemsListed[_tokenId].lastBidder != address(0)) {
            token.transfer(
                _itemsListed[_tokenId].lastBidder,
                _itemsListed[_tokenId].lastBid
            );
        }

        token.transferFrom(msg.sender, address(this), _amount);
        _itemsListed[_tokenId].lastBid = _amount;
        _itemsListed[_tokenId].lastBidder = msg.sender;
        _itemsListed[_tokenId].bidsCount++;
    }

    function finishAuction(uint256 _tokenId) public nonReentrant {
        require(
            (block.timestamp - _itemsListed[_tokenId].auctionStartTime) >=
                auctionDuration * 1 days,
            "Min action duration isn't yet reached"
        );

        address _oldOwner = _itemsListed[_tokenId].owner;

        if (_itemsListed[_tokenId].bidsCount > 2) {
            nft.transferFrom(
                _itemsListed[_tokenId].owner,
                _itemsListed[_tokenId].lastBidder,
                _tokenId
            );
            token.transfer(
                _itemsListed[_tokenId].owner,
                _itemsListed[_tokenId].lastBid
            );
            address _newOwner = _itemsListed[_tokenId].lastBidder;
            emit AuctionFinished(_oldOwner, _newOwner, _tokenId);
        } else {
            token.transfer(
                _itemsListed[_tokenId].lastBidder,
                _itemsListed[_tokenId].lastBid
            );
            emit AuctionFinished(_oldOwner, _oldOwner, _tokenId);
        }

        delete _itemsListed[_tokenId];
    }

    function cancelAuction(uint256 _tokenId) public {
        require(
            msg.sender == nft.ownerOf(_tokenId),
            "Only owner can cancel auction"
        );
        require(
            (block.timestamp - _itemsListed[_tokenId].auctionStartTime) >=
                auctionDuration * 1 days,
            "Min action duration isn't yet reached"
        );

        uint256 lastbid = _itemsListed[_tokenId].lastBid;
        address lastBidder = _itemsListed[_tokenId].lastBidder;

        _itemsListed[_tokenId].onAuction = false;
        _itemsListed[_tokenId].auctionStartTime = 0;
        _itemsListed[_tokenId].bidsCount = 0;
        _itemsListed[_tokenId].lastBid = 0;
        _itemsListed[_tokenId].lastBidder = address(0);

        if (lastBidder != address(0)) {
            token.transfer(lastBidder, lastbid);
        }

        emit AuctionCanceled(_tokenId);
    }

    event Listed(address _owner, uint256 _tokenId, uint256 _price);
    event Unlisted(address owner, uint256 _tokenId);
    event Sold(
        address _owner,
        address _buyer,
        uint256 _tokenId,
        uint256 _price
    );
    event SetOnAuction(address _owner, uint256 _tokenId, uint256 startingPrice);
    event AuctionFinished(
        address _oldOwner,
        address _newOwner,
        uint256 _tokenId
    );
    event AuctionCanceled(uint256 _tokenId);
}
