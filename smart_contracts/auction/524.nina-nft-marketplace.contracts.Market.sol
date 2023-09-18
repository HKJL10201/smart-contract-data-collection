//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Market is ReentrancyGuard {
    using Counters for Counters.Counter;
    enum MarketItemStatus {
        ITEM_LIST,
        ITEM_OPEN_FOR_SELL
    }
    Counters.Counter private _itemIds;
    Counters.Counter private _itemSold;

    address payable owner;
    uint256 listingPrice = 0.025 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable owner;
        uint256 price;
        MarketItemStatus status;
    }

    mapping(uint256 => MarketItem) private idsToMarketItem;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address owner,
        MarketItemStatus status
    );

    event MarketItemOpenForSale(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address owner,
        MarketItemStatus status
    );

    event MarketItemSold(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address owner,
        address seller
    );

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function listMarketItem(address nftContract, uint256 tokenId) public {
        _itemIds.increment();
        uint256 newItemId = _itemIds.current();
        idsToMarketItem[newItemId] = MarketItem(
            newItemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            0 ether,
            MarketItemStatus.ITEM_LIST
        );

        emit MarketItemCreated(
            newItemId,
            nftContract,
            tokenId,
            msg.sender,
            MarketItemStatus.ITEM_LIST
        );
    }

    function listItemForSale(uint256 price, uint256 itemId) public {
        require(
            idsToMarketItem[itemId].owner == msg.sender,
            "You don't own this NFT"
        );
        require(
            price > listingPrice,
            "price should be more than listing price"
        );

        idsToMarketItem[itemId].price = price;
        idsToMarketItem[itemId].status = MarketItemStatus.ITEM_OPEN_FOR_SELL;

        emit MarketItemOpenForSale(
            itemId,
            idsToMarketItem[itemId].nftContract,
            idsToMarketItem[itemId].tokenId,
            msg.sender,
            idsToMarketItem[itemId].status
        );
    }

    function saleItem(uint256 itemId) public payable {
        require(idsToMarketItem[itemId].price <= msg.value);

        uint256 offeredPrice = msg.value;
        address sender = msg.sender;
        address owner = idsToMarketItem[itemId].owner;

        idsToMarketItem[itemId].owner.transfer(offeredPrice);
        IERC721(idsToMarketItem[itemId].nftContract).transferFrom(
            owner,
            sender,
            idsToMarketItem[itemId].tokenId
        );
        idsToMarketItem[itemId].owner = payable(sender);
        idsToMarketItem[itemId].status = MarketItemStatus.ITEM_LIST;
        _itemSold.increment();

        emit MarketItemSold(
            itemId,
            idsToMarketItem[itemId].nftContract,
            idsToMarketItem[itemId].tokenId,
            owner,
            sender
        );
    }

    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 currentCount = _itemIds.current();
        uint256 myNFTCount = 0;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < currentCount; i++) {
            uint256 latest = i + 1;
            if (idsToMarketItem[latest].owner == msg.sender) {
                myNFTCount = myNFTCount + 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](myNFTCount);
        for (uint256 i = 0; i < currentCount; i++) {
            uint256 latest = i + 1;
            if (idsToMarketItem[latest].owner == msg.sender) {
                MarketItem memory item = idsToMarketItem[latest];
                items[currentIndex] = item;
                currentIndex = currentIndex + 1;
            }
        }
        return items;
    }

    function getAllNFTs() public view returns (MarketItem[] memory) {
        uint256 totalCount = _itemIds.current();
        uint256 currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](totalCount);
        for (uint256 i = 0; i < totalCount; i++) {
            MarketItem memory item = idsToMarketItem[i + 1];
            items[currentIndex] = item;
            currentIndex++;
        }
        return items;
    }
}
