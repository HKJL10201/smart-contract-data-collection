// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "./Marketplace.sol";
import "./BiDirectionalChannel.sol";

/**
@title Product
@dev Represents a product in the marketplace.
*/
contract Product {
    address payable public owner; // Address of the owner
    string public name; // Name of the product
    uint256 public price; // Price of the product
    address public productAddr; // Address of the product contract
    bool public available; // Flag indicating if the product is available

    event BuyEvent(address indexed buyer, uint256 value); // Event emitted when a product is purchased

    event UpdateEvent(string name, uint256 price); // Event emitted when the product details are updated

    /**
    @dev Modifier to check if the caller is the owner of the contract.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    /**
    @dev Modifier to check if the owner address is valid.
    */
    modifier validAddress() {
        require(owner != address(0) && owner != address(this), "Invalid address");
        _;
    }

    /**
    @dev Modifier to check if the product is available for update.
    */
    modifier onlyAvailable() {
        require(available, "Product is not available for update");
        _;
    }

    /**
    @dev Constructor function.
    @param _owner The address of the product owner.
    @param _name The name of the product.
    @param _price The price of the product.
    */
    constructor(address payable _owner, string memory _name, uint256 _price) payable {
        owner = _owner;
        name = _name;
        price = _price;
        productAddr = address(this);
        available = true;
    }

    /**
    @dev Buy function.
    Allows a user to purchase the product by sending enough funds.
    Emits a BuyEvent and transfers the funds to the product owner.
    */
    function buy() public payable validAddress {
        // Ensure that the buyer has sent enough funds
        require(msg.value >= price, "The ETH amount sent is less than the product price.");
        require(owner != address(0), "Error: Invalid owner address.");
        require(available, "Error: Product not available");

        available = false;

        // Transfer the funds from the buyer to the product owner
        (bool success, ) = owner.call{ value: price }("");
        require(success, "Transaction failed");

        emit BuyEvent(msg.sender, price);
    }

    /**
    @dev Update function.
    Allows the owner to update the name and price of the product.
    Emits an UpdateEvent with the updated details.
    @param _name The new name of the product.
    @param _price The new price of the product.
    */
    function update(string memory _name, uint256 _price) public onlyOwner onlyAvailable {
        require(_price > 0, "Price must be a positive value");

        name = _name;
        price = _price;
        emit UpdateEvent(_name, _price);
    }

    /**
    @dev Checks if the product is available for purchase.
    @return A boolean indicating if the product is available.
    */
    function isAvailable() public view returns (bool) {
        return available;
    }

    /**
    @dev Sets the availability of the product.
    Only the owner can call this function.
    @param _available The new availability status of the product.
    */
    function setAvailable(bool _available) public onlyOwner {
        available = _available;
    }

    /**
    @dev Sets the price of the product.
    Only the owner can call this function.
    @param _price The new price of the product.
    */
    function setPrice(uint256 _price) public onlyOwner {
        require(_price > 0, "Price must be a positive value");
        price = _price;
        emit UpdateEvent(name, price);
    }

    /**
    @dev Sets the name of the product.
    Only the owner can call this function.
    @param _name The new name of the product.
    */
    function setName(string memory _name) public onlyOwner {
        require(bytes(_name).length > 0, "Name must not be empty");
        name = _name;
        emit UpdateEvent(name, price);
    }

    /**
    @dev Sets the owner address of the product.
    Only the owner can call this function.
    @param _newOwner The new owner address.
    */
    function setOwner(address payable _newOwner) public validAddress onlyOwner {
        owner = _newOwner;
    }

    // TODO: replace marketplaceAddress with constant
    // New function to change the ownership of the product
    function transferOwnership(address payable _newOwner, address _marketplaceAddress) public validAddress {
        require(msg.sender == _marketplaceAddress, "Only the marketplace can call this function");
        owner = _newOwner;
    }

    /**
    @dev Gets the owner of the product.
    @return The address of the product's owner.
    */
    function getOwner() public view returns (address payable) {
        return owner;
    }

    /**
    @dev Fallback function to receive ETH payments.
    */
    receive() external payable {}
}
