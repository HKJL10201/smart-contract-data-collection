// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NftMarketplace__PriceMustBeAboveZero();
error NftMarketplace__NftNotApproved();
error NftMarketplace__AlreadyListed();
error NftMarketplace__NotOwner();
error NftMarketplace__NotListed();
error NftMarketplace__InvalidAmountSent();
error NftMarketplace__NoProceeds();
error NftMarketplace__TranferFailed();

contract NftMarketplace is ReentrancyGuard {

    struct Listing {
        uint256 price;
        address seller;
    }
    event ItemListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ItemBought(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event listingCancelled(address indexed nftAddress, uint256 indexed tokenId);

    // Nft Contract address -> Nft tokenID -> Listing
    mapping (address => mapping (uint256 => Listing)) private listings;
    mapping (address => uint256) private proceeds;

    modifier notListed (address nftAddress, uint256 tokenId, address owner) {
        Listing memory listing = listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert NftMarketplace__AlreadyListed();
        }
        _;
    }

    modifier isOwner (address nftAddress, uint256 tokenId, address spender) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NftMarketplace__NotOwner();
        }
        _;
    }

    modifier isListed (address nftAddress, uint256 tokenId) {
        Listing memory listing = listings[nftAddress][tokenId];
        if (listing.price == 0) {
            revert NftMarketplace__NotListed();
        }
        _;
    }

    /////////Main Functions/////////////

    function listItem(address nftAddress, uint256 tokenId, uint256 price) external 
    notListed(nftAddress, tokenId, msg.sender)
    isOwner (nftAddress, tokenId, msg.sender) 
    {
        if (price <= 0) {
            revert NftMarketplace__PriceMustBeAboveZero();
        }

        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketplace__NftNotApproved();
        }

        listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);

    }

    function buyItem(address nftAddress, uint256 tokenId) external payable nonReentrant isListed (nftAddress, tokenId) {
        Listing memory listedItem = listings[nftAddress][tokenId];
        if (listedItem.price > msg.value) {
            revert NftMarketplace__InvalidAmountSent();
        }

        proceeds[listedItem.seller] += msg.value;
        delete listings[nftAddress][tokenId];

        IERC721 nft = IERC721(nftAddress);
        nft.safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price); 
    }

    function cancelListing(address nftAddress, uint256 tokenId) external 
    isOwner (nftAddress, tokenId, msg.sender) 
    isListed (nftAddress, tokenId) {
        delete listings[nftAddress][tokenId];
        emit listingCancelled(nftAddress, tokenId);
    }

    function updateListing(address nftAddress, uint256 tokenId, uint256 newPrice) external 
    isOwner(nftAddress, tokenId, msg.sender)
    isListed (nftAddress, tokenId) {
        Listing memory listing = listings[nftAddress][tokenId];
        if (newPrice <= 0) {
            revert NftMarketplace__PriceMustBeAboveZero();
        }
        listing.price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }

    function withdrawProceeds() external payable {
        uint256 balance = proceeds[msg.sender];
        if(balance <= 0) {
            revert NftMarketplace__NoProceeds();
        }
        proceeds[msg.sender] = 0;
        (bool success,) = payable(msg.sender).call{value: balance}("");
        if(!success) {
            revert NftMarketplace__TranferFailed();
        }
        
    }

    function getProceeds(address seller) public view returns (uint256) {
        return proceeds[seller];
    }

    function getListing(address nftAddress, uint256 tokenId) public view returns (Listing memory) {
        return listings[nftAddress][tokenId];
    }

}
