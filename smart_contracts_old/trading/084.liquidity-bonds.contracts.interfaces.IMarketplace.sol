// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

interface IMarketplace {

    struct MarketplaceListing {
        address seller;
        bool exists;
        uint256 ID;
        uint256 price; // Denominated in TGEN.
    }

    /**
    * @dev Given an NFT ID, returns its listing index.
    * @notice Returns 0 if the NFT with the given ID is not listed.
    * @param _ID ID of the ExecutionPrice NFT.
    * @return uint256 Listing index of the ExecutionPrice NFT.
    */
    function getListingIndex(uint256 _ID) external view returns (uint256);

    /**
    * @dev Given the index of a marketplace listing, returns the listing's data
    * @param _index Index of the marketplace listing
    * @return (address, bool, uint256, uint256) Address of the seller, whether the listing exists, NFT ID, and the price (in TGEN).
    */
    function getMarketplaceListing(uint256 _index) external view returns (address, bool, uint256, uint256);

    /**
    * @dev Purchases the ExecutionPrice NFT at the given listing index.
    * @param _index Index of the marketplace listing.
    */
    function purchase(uint256 _index) external;

    /**
    * @dev Creates a new marketplace listing with the given price and NFT ID.
    * @param _ID ID of the ExecutionPrice NFT.
    * @param _price TGEN price of the NFT.
    */
    function createListing(uint256 _ID, uint256 _price) external;

    /**
    * @dev Removes the marketplace listing at the given index.
    * @param _index Index of the marketplace listing.
    */
    function removeListing(uint256 _index) external;

    /**
    * @dev Updates the price of the given marketplace listing.
    * @param _index Index of the marketplace listing.
    * @param _newPrice TGEN price of the NFT.
    */
    function updatePrice(uint256 _index, uint256 _newPrice) external;

    /* ========== EVENTS ========== */

    event CreatedListing(address indexed seller, uint256 marketplaceListingIndex, uint256 ID, uint256 price);
    event RemovedListing(address indexed seller, uint256 marketplaceListingIndex);
    event UpdatedPrice(address indexed seller, uint256 marketplaceListingIndex, uint256 newPrice);
    event Purchased(address indexed buyer, uint256 marketplaceListingIndex, uint256 ID, uint256 price);
}