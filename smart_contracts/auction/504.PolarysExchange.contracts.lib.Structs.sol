// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum AssetType {
    ERC721,
    ERC1155
}

enum Action {
    SELL,
    BUY,
    RESERVED_PRICE,
    AUCTION_BID,
    CLAIM,
    CANCEL
}

struct Order {
    AssetType asset;
    Action action;
    address collection;
    address paymentToken;
    address seller; 
    address buyer; 
    uint256 tokenId;
    uint256 price;
    uint256 expirationTime; 
    uint256 tokenAmount; //Option for ERC1155
}

struct Auction {
    AssetType asset;
    Action action; 
    address collection; 
    address paymentToken; 
    address seller;
    address highestBidder;
    uint256 tokenId; 
    uint256 reservedPrice;
    uint256 highestBid; 
    uint256 startTime;
    uint256 expirationTime; 
    uint256 tokenAmount; 
}
