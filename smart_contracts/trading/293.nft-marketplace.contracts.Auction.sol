// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract Auction {
    event AuctionCreated(uint256 indexed tokenId, address indexed seller, uint256 duration);
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 value);
    event AuctionEnded(uint256 indexed tokenId, address indexed winner, uint256 value);

    struct AuctionInfo {
        uint256 tokenId;
        address payable seller;
        uint256 duration;
        uint256 startedAt;
        uint256 price;
        address payable
