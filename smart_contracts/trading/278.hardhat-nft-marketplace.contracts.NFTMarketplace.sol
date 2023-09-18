// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NFTMarketplace__PriceMustBeAboveZero();
error NFTMarketplace__NotApprovedForMarketplace();
error NFTMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
error NFTMarketplace__NotListed(address nftAddress, uint256 tokenId);
error NFTMarketplace__PriceNotEnoughForPurchase(
  address nftAddress,
  uint256 tokenId,
  uint256 price
);
error NFTMarketplace__NoProceedsToWithdraw();
error NFTMarketplace__WithdrawTransferFailed();
error NFTMarketplace__NotOwner();

contract NFTMarketplace is ReentrancyGuard {
  // Struct
  struct Listing {
    uint256 price;
    address seller;
  }
  // Events
  event ItemListed(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price
  );

  event ItemBought(
    address indexed buyer,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price
  );

  event ItemCancelled(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId
  );
  // State Variables
  // NFT Contract address -> NFT TokenID -> Listing
  mapping(address => mapping(uint256 => Listing)) private s_listings;
  // Seller address to Price of NFT
  mapping(address => uint256) private s_proceeds;

  // Modifiers
  modifier notListed(
    address nftAddress,
    uint256 tokenId,
    address owner
  ) {
    Listing memory listing = s_listings[nftAddress][tokenId];
    if (listing.price > 0) {
      revert NFTMarketplace__AlreadyListed(nftAddress, tokenId);
    }
    _;
  }

  modifier isListed(address nftAddress, uint256 tokenId) {
    Listing memory listing = s_listings[nftAddress][tokenId];
    if (listing.price <= 0) {
      revert NFTMarketplace__NotListed(nftAddress, tokenId);
    }
    _;
  }

  modifier isOwner(
    address nftAddress,
    uint256 tokenId,
    address spender
  ) {
    IERC721 nft = IERC721(nftAddress);
    address owner = nft.ownerOf(tokenId);
    if (spender != owner) {
      revert NFTMarketplace__NotOwner();
    }
    _;
  }

  // Functions and Methods
  /**
   * @notice Method for listing NFT into Marketplace
   * @param nftAddress is the NFT address pointing to the ERC20 token standard complying contract for publishing assets to decentralized web i.e., web3
   * @param tokenId is the token id for the NFT
   * @param price is sale price listed on marketplace
   * @dev technically, we could have the contract be the escrow for the NFTs but this way people can still hold their NFTs when listed.
   */
  function listItem(
    address nftAddress,
    uint256 tokenId,
    uint256 price
  )
    external
    notListed(nftAddress, tokenId, msg.sender)
    isOwner(nftAddress, tokenId, msg.sender)
  {
    if (price <= 0) {
      revert NFTMarketplace__PriceMustBeAboveZero();
    }
    /* 
    Methods to get this done:
    1. Send the NFT to the contract, Transfer -> Contract "hold" the NFT.
    2. Owners can still hold their NFT, and give marketplace approval to sell the NFT for them.
    
    We would go ahead implement 2nd method as it will provide more intuitive market for buying and selling NFTs.
    */
    IERC721 nft = IERC721(nftAddress);
    if (nft.getApproved(tokenId) != address(this)) {
      revert NFTMarketplace__NotApprovedForMarketplace();
    }

    // To implement the buyer and seller relationship along with distinctive NFTs listed on the marketplace, we require to use mapping :
    s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
    emit ItemListed(msg.sender, nftAddress, tokenId, price);
  }

  /**
   * @notice Method for buying NFTs from marketplace
   * @notice NonReentrant - to avoid reentrant vulnerable attack (this locks the function until it has fully executed)
   * @param nftAddress is the address of the NFT
   * @param tokenId is the token ID of the NFT
   * @dev The owner of an NFT could unapprove the marketplace.
   * Ideally you'd also have a `createOffer` functionality.
   */
  function buyItem(
    address nftAddress,
    uint256 tokenId
  ) external payable nonReentrant isListed(nftAddress, tokenId) {
    Listing memory listedItem = s_listings[nftAddress][tokenId];
    if (msg.value < listedItem.price) {
      revert NFTMarketplace__PriceNotEnoughForPurchase(
        nftAddress,
        tokenId,
        listedItem.price
      );
    }
    // adding the funds received to the proceeds mapping of seller so that it can be withdrawn later by the seller
    // Note: by convention developers prefer pull over push, so that sellers do not get direct transfer funds which adds risks rather they have to withdraw the funds after making a successful sale on the marketplace.
    // Sending money directly to user ❌
    // Have them withdraw the money instead ✅
    s_proceeds[listedItem.seller] = s_proceeds[listedItem.seller] + msg.value;
    // removing the NFT from the marketplace once it has been purchased.
    delete (s_listings[nftAddress][tokenId]);
    // safeTranferFrom throws an error if something goes wrong during transfer so that the error doesn't go unnoticed in the blockchain marketplace.
    // Note: We only transfer the funds after updating the block state to avoid a dangerous and malicious attack know as Reentrant Vulnerable attack.
    IERC721(nftAddress).safeTransferFrom(
      listedItem.seller,
      msg.sender,
      tokenId
    );
    // emitting an event for success of transfer -
    emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
  }

  /**
   * @notice Method to remove a NFT from listing of Marketplace.
   * @param nftAddress is address of NFT
   * @param tokenId is token ID of NFT
   * @dev Only owner of the listing/ NFT owner can remove the NFT from listing and only an already listed NFT item can be removed from listing.
   */
  function cancelListing(
    address nftAddress,
    uint256 tokenId
  )
    external
    isOwner(nftAddress, tokenId, msg.sender)
    isListed(nftAddress, tokenId)
  {
    delete (s_listings[nftAddress][tokenId]);
    emit ItemCancelled(msg.sender, nftAddress, tokenId);
  }

  /**
   * @notice Method to update a listing in marketplace
   * @param nftAddress is the address of the NFT
   * @param tokenId is the token ID of the NFT
   * @param newPrice is new price for the NFT sale (update value)
   * @dev Only owner of the listing/ NFT owner can update the NFT from listing and only an already listed NFT can be updated.
   */
  function updateListing(
    address nftAddress,
    uint256 tokenId,
    uint256 newPrice
  )
    external
    isListed(nftAddress, tokenId)
    isOwner(nftAddress, tokenId, msg.sender)
  {
    if (newPrice <= 0) {
      revert NFTMarketplace__PriceMustBeAboveZero();
    }
    s_listings[nftAddress][tokenId].price = newPrice;
    emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
  }

  function withdrawProceeds() external nonReentrant {
    uint256 proceeds = s_proceeds[msg.sender];
    if (proceeds <= 0) {
      revert NFTMarketplace__NoProceedsToWithdraw();
    }
    s_proceeds[msg.sender] = 0;
    (bool success, ) = payable(msg.sender).call{value: proceeds}("");
    if (!success) {
      revert NFTMarketplace__WithdrawTransferFailed();
    }
  }

  // View / Pure functions
  function getListing(
    address nftAddress,
    uint256 tokenId
  ) external view returns (Listing memory) {
    return s_listings[nftAddress][tokenId];
  }

  function getProceeds(address seller) external view returns (uint256) {
    return s_proceeds[seller];
  }
}
