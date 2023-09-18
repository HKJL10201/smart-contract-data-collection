pragma solidity >=0.5.0;

import "../vendor/VendorInterface.sol";
import "./FarmerInterface.sol";

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FarmerContract is FarmerInterface {

    /* Usings */

    using SafeMath for uint256;


    /* Structs */

    struct Farmer {
        bytes32 ipfsHash;
        uint256 trust;
        uint256 reviewers;
    }

    struct Item {
        bytes32 ipfsHash;
        uint256 id;
        bool isSold;
    }


    /* Public variables */

    /* Contract owner address */
    address public owner;

    /* Vendor contract address */
    VendorInterface public vendor;


    /* Mappings*/

    /* Mapping for farmer struct */
    mapping (address /* farmer address */ => Farmer) public farmers;

    /* Mapping for Item array */
    mapping (address /* farmer address */ => Item[]) public items;

    /* Mapping for record of products sold */
    mapping (address => mapping (address => mapping (uint256 => bool))) public soldProducts;

    /* Mapping for update trust */
    mapping (address => mapping (address => mapping (uint256 => bool))) public updateTrust;


    /* Modifiers */

    /* Modifier to check caller is a vendor. */
    modifier onlyVendor() {
        require(
            vendor.isVendor(msg.sender),
            "Only vendor can call."
        );
        _;
    }

    /* Modifier to check caller is a farmer. */
    modifier onlyFarmer() {
        require(
            farmers[msg.sender].ipfsHash != bytes32(0),
            "Only farmer can call"
        );
        _;
    }


    /* Public Functions */

    /**
     * Set vendor contract address - only called once.
     * @param _vendorContract - vendor contract address.
     */
    function setVendorContractAddress(address _vendorContract) public {
        vendor = VendorInterface(_vendorContract);
    }

    /**
     *  Add farmer to the mapping
                - farmer must not already present
                - farmer address must not be empty
                - ipfs hash must not be empty
                - initial trust
     * @param
                _ipfsHash - hash of farmer data stored on ipfs
                _name - farmer
     */
    function addFarmer(bytes32 _ipfsHash)
        public
    {
        require(
            _ipfsHash != bytes32(0),
            "IPFS hash must not be zero"
        );

        require(
            farmers[msg.sender].ipfsHash == bytes32(0),
            "Farmer already exists."
        );

        Farmer memory farmer = Farmer({
            ipfsHash: _ipfsHash,
            trust: uint256(5),
            reviewers: uint256(0)
        });

        farmers[msg.sender] = farmer;
    }

    /**
     * Add item to the array of items and the mapping
                - IPFS hash of item must not be empty
                - id must not be zero
     * @param
                _itemIpfsHash - hash of item data stored on ipfs
                _id - id of the item
     */
    function addItem(bytes32 _itemIpfsHash)
        public
        onlyFarmer
    {
        require(
            _itemIpfsHash != bytes32(0),
            "IPFS hash must not be zero"
        );

        uint256 itemLength = items[msg.sender].length;

        Item memory item = Item({
            ipfsHash: _itemIpfsHash,
            id: itemLength,
            isSold: false
        });

        items[msg.sender].push(item);
    }

    /**
     * Returns count of items belongs to `_farmerAddress`
     * @param _farmerAddress - Farmer address
     *
     * @return itemsLength - length of item array corresponding
     *                       `_farmerAddress`.
     */
    function getItemCount(address _farmerAddress) public view returns (uint256 itemsLength) {
        itemsLength = items[_farmerAddress].length;
    }

    /**
     * update farmer's trust value
     * @param _farmer - farmer address.
     * @param _trust - trust value provided by vendor.
     */
    function updateFarmerTrust(address _farmer, uint256 _productId, uint256 _trust)
        public
        onlyVendor
    {
        require (
            vendor.isVendor(msg.sender) == true,
            "Vendor must exist."
        );
        require(
            farmers[_farmer].ipfsHash != bytes32(0),
            "Farmer must exist"
        );
        require (
            _trust > 0 && _trust <= 5,
            "Trust value cannot be zero and cannot be greater than 5"
        );
        require(
            soldProducts[msg.sender][_farmer][_productId] == true,
            "Trade must be successful before updating trust."
        );
        require(
            updateTrust[msg.sender][_farmer][_productId] == false,
            "Multiple trust updations for same product is not allowed."
        );

        updateTrust[msg.sender][_farmer][_productId] = true;
        farmers[_farmer].trust = farmers[_farmer].trust.add(_trust);
    }

    /**
     * Check for farmer exist or not
     * @param _farmer - farmer address
     *
     * @return bool - whether farmer is present or not
     */
    function isFarmer(address _farmer)
        external
        returns (bool)
    {
        return (farmers[_farmer].ipfsHash != bytes32(0));
    }

    /**
     * Get farmer details
     * @param _farmer - farmer address
     *
     * @return farmer ipfs hash
     *         farmer trust
     *         farmer reviewers
     */
    function getFarmer(address _farmer)
        public
        view
        returns (bytes32, uint256, uint256)
    {
        require(
            _farmer != address(0),
            "Farmer address cannot be empty."
        );
        require(
            farmers[_farmer].ipfsHash != bytes32(0),
            "Farmer must exist."
        );

        return (
            farmers[_farmer].ipfsHash,
            farmers[_farmer].trust,
            farmers[_farmer].reviewers
        );
    }

    /**
     * Get product status - sold or not.
     *
     * @param _farmer - farmer address
     * @param _productId - product id
     *
     * @return bool - whether product is sold or not
     *                true - sold
     *                false - not sold
     */
    function getProductStatus(address _farmer, uint256 _productId)
        public
        view
        returns (bool)
    {
        return items[_farmer][_productId].isSold;
    }

    /**
     * Set product status as sold - only vendor can call.
     *
     * @param _farmer - farmer address
     * @param _productId - product id
     */
    function setProductAsSold(address _vendor, address _farmer, uint256 _productId)
        external
    {
        require(
            farmers[_farmer].ipfsHash != bytes32(0),
            "Farmer must exist."
        );
        require(
            items[_farmer][_productId].isSold == false,
            "Product must be available for sell."
        );

        soldProducts[_vendor][_farmer][_productId] = true;
        items[_farmer][_productId].isSold = true;
    }

    function getTradeStatus(address _vendor, address _farmer, uint256 _productId)
        public
        view
        returns (bool tradeStatus)
    {
        tradeStatus = soldProducts[_vendor][_farmer][_productId];
    }
}
