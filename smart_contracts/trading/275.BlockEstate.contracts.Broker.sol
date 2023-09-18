// SPDX-License-Identifier: Unlicense
// This contract implements a simple NFT (ERC721) broker that allows users to buy, sell, and list properties (land)
// It is built using the OpenZeppelin Solidity library to ensure security and best practices in the code

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**

@title BlockEstate
@dev A smart contract for buying and selling land properties
*/

// ERC721 interface to transfer tokens
interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _id) external;
}

contract Broker is ReentrancyGuard {
    // Define variables
    address payable public contractOwner; // owner of the contract
    uint256 public listingFees = 0.01 ether; // listing fees for each property
    address public nftAddress; // address of the NFT (ERC721) contract

    // Counter to keep track of number of properties listed
    uint256 count;

    // Struct to define the properties of a land
    struct Land {
        uint256 propertyId; // unique identifier of the land
        address payable owner; // current owner of the land
        address payable seller; // seller of the land
        uint256 price; // price of the land
        bool listed; // boolean to indicate if the land is currently listed for sale
        bool reSold; // boolean to indicate if the land has been resold
    }

    // Mapping to keep track of all the properties listed for sale
    mapping(uint256 => Land) public property;

    constructor() {
        contractOwner = payable(msg.sender);
    }

    // Event to emit when a property is listed for sale
    event propertyListed(
        uint256 propertyId,
        address owner,
        address seller,
        uint256 price
    );

    // Event to emit when a property is sold
    event propertySold(
        uint256 propertyId,
        address owner,
        address seller,
        uint256 price
    );

    // Event to emit when a property is Resold
    event propertyResold(
        uint256 propertyId,
        address owner,
        address seller,
        uint256 price
    );

    // Function to list a property for sale
    function listProperties(
        uint256 _price,
        uint256 _propertyId,
        address _propertyContract
    ) public payable nonReentrant {
        require(_price > 0, "Price must be more than 0"); // Check that price is greater than 0
        require(msg.value == listingFees, "Not enough ether for listing fee"); // Check that user has paid the listing fee
        IERC721(_propertyContract).transferFrom(
            msg.sender,
            address(this),
            _propertyId
        ); // Transfer ownership of the land to the broker contract
        contractOwner.transfer(listingFees); // Transfer listing fees to contract owner

        // Create a new Land object and add it to the property mapping
        property[_propertyId] = Land(
            _propertyId,
            payable(address(this)),
            payable(msg.sender),
            _price,
            true,
            false
        );
        emit propertyListed(_propertyId, address(this), msg.sender, _price); // Emit event for property listed
    }

    // Function to buy a property
    function buyProperties(
        uint256 _propertyId,
        address _propertyContract
    ) public payable nonReentrant {
        Land storage estate = property[_propertyId]; // Get the Land object for the given propertyId
        require(
            msg.value >= estate.price,
            "Not enough ether to cover asking price"
        ); // Check that buyer has sent enough ether to cover the price of the land
        address payable buyer = payable(msg.sender); // Set buyer to the sender of the transaction
        payable(estate.seller).transfer(msg.value); // Transfer money from buyer to seller
        IERC721(_propertyContract).transferFrom(
            address(this),
            buyer,
            estate.propertyId
        ); // Transfer ownership of the land from broker contract to buyer

        estate.owner = buyer;
        estate.seller = buyer;
        estate.listed = false;

        emit propertySold(_propertyId, buyer, estate.seller, estate.price); // Emit event for property sold
    }

    // Function to resell a property
    function resellProperties(
        uint256 _price,
        uint256 _propertyId,
        address _propertyContract
    ) public payable nonReentrant {
        require(_price > 0, "Price must be more than 0"); // Check that price is greater than 0
        require(msg.value == listingFees, "Not enough ether for listing fee"); // Check that user has paid the listing fee

        Land storage estate = property[_propertyId]; // Get the Land object for the given propertyId

        IERC721(_propertyContract).transferFrom(
            msg.sender,
            address(this),
            _propertyId
        ); // Transfer ownership of the land to the broker contract

        contractOwner.transfer(listingFees);

        estate.price = _price;
        estate.owner = payable(address(this));
        estate.seller = payable(msg.sender);
        estate.listed = true;
        estate.reSold = true;

        emit propertyResold(_propertyId, address(this), msg.sender, _price); // Emit event for property Resold
    }

    //Function to withdraw excessive funds

    function withdraw() public {
        require(
            address(this).balance > 0,
            "Withdraw value must be more than 0"
        );
        contractOwner.transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}

    //Function to return balance of contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
