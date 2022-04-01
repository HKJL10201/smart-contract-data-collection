// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

//Openzeppelin
import "./openzeppelin-solidity/contracts/SafeMath.sol";
import "./openzeppelin-solidity/contracts/Ownable.sol";
import "./openzeppelin-solidity/contracts/ERC20/SafeERC20.sol";
import "./openzeppelin-solidity/contracts/ERC1155/IERC1155.sol";
import "./openzeppelin-solidity/contracts/ERC1155/ERC1155Holder.sol";

//Inheritance
import './interfaces/IMarketplace.sol';

contract Marketplace is IMarketplace, ERC1155Holder, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Max fee of 10%.
    uint256 public MAX_TRANSACTION_FEE = 1000; 

    // Denominated by 10000.
    uint256 public transactionFee = 200; 

    IERC1155 public immutable priceManager;
    IERC20 public immutable TGEN;
    address public immutable xTGEN;

    // Starts at index 1; increases without bounds.
    uint256 public numberOfMarketplaceListings;

    // Starts at index 1; increases without bounds.
    mapping (uint256 => MarketplaceListing) public marketplaceListings; 

    // NFT ID => listing index.
    // Returns 0 if the NFT is listed for sale.
    mapping (uint256 => uint256) public listingIndexes; 

    // User address => NFT ID => listing index.
    // Returns 0 if user is not selling the NFT ID.
    mapping (address => mapping (uint256 => uint256)) public userToID; 

    constructor(address _priceManager, address _TGEN, address _xTGEN) Ownable() {
        require(_priceManager != address(0), "Marketplace: invalid address for PriceManager.");
        require(_TGEN != address(0), "Marketplace: invalid address for TGEN.");
        require(_xTGEN != address(0), "Marketplace: invalid address for xTGEN.");

        priceManager = IERC1155(_priceManager);
        TGEN = IERC20(_TGEN);
        xTGEN = _xTGEN;
    }

    /* ========== VIEWS ========== */

   /**
    * @dev Given an NFT ID, returns its listing index.
    * @notice Returns 0 if the NFT with the given ID is not listed.
    * @param _ID ID of the ExecutionPrice NFT.
    * @return uint256 Listing index of the ExecutionPrice NFT.
    */
    function getListingIndex(uint256 _ID) external view override returns (uint256) {
        return listingIndexes[_ID];
    }

    /**
    * @dev Given the index of a marketplace listing, returns the listing's data
    * @param _index Index of the marketplace listing
    * @return (address, bool, uint256, uint256) Address of the seller, whether the listing exists, NFT ID, and the price (in TGEN).
    */
    function getMarketplaceListing(uint256 _index) external view override indexInRange(_index) returns (address, bool, uint256, uint256) {
        MarketplaceListing memory listing = marketplaceListings[_index];

        return (listing.seller, listing.exists, listing.ID, listing.price);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

   /**
    * @dev Purchases the ExecutionPrice NFT at the given listing index.
    * @param _index Index of the marketplace listing.
    */
    function purchase(uint256 _index) external override indexInRange(_index) {
        require(marketplaceListings[_index].exists, "Marketplace: listing does not exist.");
        require(msg.sender != marketplaceListings[_index].seller, "Marketplace: Cannot buy your own position.");

        uint256 price = marketplaceListings[_index].price;

        TGEN.safeTransferFrom(msg.sender, address(this), price);
        
        // Transfer TGEN to seller.
        TGEN.safeTransfer(marketplaceListings[_index].seller, price.mul(10000 - transactionFee).div(10000));

        // Transfer TGEN to xTGEN contract.
        TGEN.safeTransfer(xTGEN, price.mul(transactionFee).div(10000));

        // Transfer NFT to buyer.
        priceManager.setApprovalForAll(msg.sender, true);
        priceManager.safeTransferFrom(address(this), msg.sender, marketplaceListings[_index].ID, 1, "");

        // Update state variables.
        _removeListing(marketplaceListings[_index].seller, _index);

        emit Purchased(msg.sender, _index, marketplaceListings[_index].ID, marketplaceListings[_index].price);
    }

    /**
    * @dev Creates a new marketplace listing with the given price and NFT ID.
    * @param _ID ID of the ExecutionPrice NFT.
    * @param _price TGEN price of the NFT.
    */
    function createListing(uint256 _ID, uint256 _price) external override {
        require(userToID[msg.sender][_ID] == 0, "Marketplace: Already have a marketplace listing for this NFT.");
        require(_price > 0, "Marketplace: Price must be greater than 0");
        require(priceManager.balanceOf(msg.sender, _ID) == 1, "Marketplace: don't own NFT.");

        numberOfMarketplaceListings = numberOfMarketplaceListings.add(1);
        listingIndexes[_ID] = numberOfMarketplaceListings;
        userToID[msg.sender][_ID] = numberOfMarketplaceListings;
        marketplaceListings[numberOfMarketplaceListings] = MarketplaceListing(msg.sender, true, _ID, _price);

        // Transfer NFT to marketplace.
        priceManager.safeTransferFrom(msg.sender, address(this), _ID, 1, "");

        emit CreatedListing(msg.sender, numberOfMarketplaceListings, _ID, _price);
    }

    /**
    * @dev Removes the marketplace listing at the given index.
    * @param _index Index of the marketplace listing.
    */
    function removeListing(uint256 _index) external override indexInRange(_index) onlySeller(_index) {
        _removeListing(msg.sender, _index);

        // Transfer NFT to seller.
        priceManager.setApprovalForAll(msg.sender, true);
        priceManager.safeTransferFrom(address(this), msg.sender, marketplaceListings[_index].ID, 1, "");

        emit RemovedListing(msg.sender, _index);
    }

    /**
    * @dev Updates the price of the given marketplace listing.
    * @param _index Index of the marketplace listing.
    * @param _newPrice TGEN price of the NFT.
    */
    function updatePrice(uint256 _index, uint256 _newPrice) external override indexInRange(_index) onlySeller(_index) {
        require(_newPrice > 0, "Marketplace: New price must be greater than 0");

        marketplaceListings[_index].price = _newPrice;

        emit UpdatedPrice(msg.sender, _index, _newPrice);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Updates the transaction fee.
    * @notice This function is meant to be called by the contract deployer.
    * @param _newFee The new transaction fee.
    */
    function setTransactionFee(uint256 _newFee) external onlyOwner {
        require(_newFee >= 0, "Marketplace: new fee must be positive.");
        require(_newFee <= MAX_TRANSACTION_FEE, "Marketplace: new fee is too high.");

        transactionFee = _newFee;

        emit UpdatedTransactionFee(_newFee);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @dev Sets the marketplace listing's 'exists' variable to false.
    * @param _user Address of the seller.
    * @param _index Index of the marketplace listing.
    */
    function _removeListing(address _user, uint256 _index) internal {
        marketplaceListings[_index].exists = false;
        userToID[_user][marketplaceListings[_index].ID] = 0;
    }

    /* ========== MODIFIERS ========== */

    modifier indexInRange(uint256 index) {
        require(index > 0 &&
                index <= numberOfMarketplaceListings,
                "Marketplace: Index out of range");
        _;
    }

    modifier onlySeller(uint256 index) {
        require(msg.sender == marketplaceListings[index].seller,
                "Marketplace: Only the seller can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event UpdatedTransactionFee(uint256 newFee);
}