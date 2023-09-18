// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract Marketplace {
    event ListingCreated(uint256 indexed tokenId, address indexed seller, uint256 price);
    event OfferCreated(uint256 indexed tokenId, address indexed buyer, uint256 value);
    event OfferAccepted(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 value);
    event SaleCompleted(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 value);

    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
    }

    struct Offer {
        uint256 tokenId;
        address buyer;
        uint256 value;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Offer) public offers;
    mapping(address => mapping(uint256 => bool)) public canOffer;

    ERC721 public nft;

    constructor(address _nft) {
        nft = ERC721(_nft);
    }

    function createListing(uint256 tokenId, uint256 price) external;
    function makeOffer(uint256 tokenId) external payable;
    function acceptOffer(uint256 tokenId, uint256 minPrice) external;
    function completeSale(uint256 tokenId) external;
}
