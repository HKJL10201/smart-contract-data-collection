//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title DutchAuctionModel
 */

library DutchAuctionModel {

    enum AUCTION_STATUS {
        NOT_ASSIGNED,
        STARTED,
        SOLD,
        CLOSED
    }

    enum TOKEN_TYPE {
        ERC721
    }

    struct Auctions {
        AUCTION_STATUS status;
        TOKEN_TYPE nftType;
        address tokenOwner;
        address tokenContract;
        uint256 tokenId;
        uint256 startDate;
        uint256 startPrice;
        uint256 endDate;
        uint256 endPrice;
    }

    event AuctionCreated(
        bytes32 indexed auctionId,
        address indexed seller,
        address indexed tokenContract,
        uint256 tokenId,
        uint256 startDate,
        uint256 startPrice,
        uint256 endDate,
        uint256 endPrice
    );

    event AuctionClosed(
        bytes32 indexed auctionId,
        address indexed buyer,
        uint256 finalPrice
    );
}
