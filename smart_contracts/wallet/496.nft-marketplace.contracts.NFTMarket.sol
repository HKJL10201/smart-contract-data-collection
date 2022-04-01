// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// This is a security that allows us to protect some transactions from separate contracts, so users can't make multiple transacions or calls.
// Security control to prevent reentries attacks.
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarket is ReentrancyGuard{
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds; // Number of items in the market.
    Counters.Counter private _itemsSold;
    // Number of items sold. This is important cause we will work with arrays. We need to know the link of each value inside the array. Know how many items are sold, and which not.

    address payable owner; // Owner of the contract/transaction.
    uint256 listingPrice = 0.025 ether; // Fee to pay when deploying the item to the network, ¿buying and selling as well?

    // Set the owner as the msg.sender
    constructor(){
        owner = payable(msg.sender);  // The owner of this contract, is the person who is deploying it.
    }

    // Object that determines the data of the item.
    struct MarketItem{
        uint itemId;
        address nftContract; // Contract address
        uint256 tokenId; // id of the token
        address payable seller; // Who sells
        address payable owner; // Who buy
        uint256 price; // price of the token
        bool sold; // true or false
    }

    // Using the integrer (1, 2, 3, 4, 5...) get the specific item for that id/integrer
    // When we get this item, we will get all the data inside it (itemId, nftContract, tokenId, seller, owner, price, sold)
    mapping(uint256 => MarketItem) private idToMarketItem;

    // Event when a market item is created.
    // Listen to this event from a front-end app. Maybe we can use this event "MarketItemCreated" to get the data of that item and show it somewhere or store it somwhere.
    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    // Returns the listing price of a new item.
    function getListingPrice() public view returns (uint256){
        return listingPrice;
    }

    // Functions to interact with the contract.

    // 1. Function to create a market item and put it for sale.
    function createMarketItem(
        address nftContract, // The address of the owner/creator of the item
        uint256 tokenId, // id of the item
        uint price // Price of the item (the user decides how much)
    ) public payable nonReentrant{ // nonReentrant to prevent reentry attacks. This is a modifier.
        // Require conditions for that function:
        require(price > 0, "Price must be at least 1 wei" );

        // It's a must that the creator writes the listing price for this item.
        require(msg.value == listingPrice, "Price must be equal to listing price");

        // Id for the marketplace item
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        // Create the MarketItem
        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender), // User who sells this
            payable(address(0)), // Owner doesn't exists yet cause we don't know who buys it. (Empty address)
            price,
            false // It's sold? False at this moment.
        );

        // Transfer the ownership of the NFT to the contract itself.
        // After that, the contract will take the ownership of the NFT and be able to transfer it to the next buyer.
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        // Emmit the event that we've created before (line 44)
        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    // 2. Creating a market sale for buying or selling an item between parties.
    function createMarketSale(
        address nftContract,
        uint256 itemId
    )public payable nonReentrant{
        // With the itemId we map and destructure the market item and we can get the price and the tokenId for that item.
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;

        // Require to the buyer the price to pay.
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");


        // ********* TRANSACTIONS ************
        // Transfer the value of the transaction, how much money will be sent, to the SELLER.
        idToMarketItem[itemId].seller.transfer(msg.value);

        // Transfer the ownership of this token to the msg.sender
        // It's from the address(this) because this means that the owner at this moment is the contract itself.
        // We send to the msg.sender, who is the BUYER
        // The tokenId is actually the id of the item, of the good, of the NFT, of the digital asset.
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        // Set the local value for the owner to be the msg.sender
        idToMarketItem[itemId].owner = payable(msg.sender);
        // Set the bool sold value to true, cause now, after all the transactions, the NFT is sold.
        idToMarketItem[itemId].sold = true;

        // Keep track of the items sold array
        _itemsSold.increment(); // now is 0 to 1, or 5 to 6 items sold on the market.

        // Pay the owner of the contract - Transfer the amount of the listing price that the first owner put when it wanted to sell the NFT.
        payable(owner).transfer(listingPrice);

    }

    // Utility functions to interact with our Market Place
    // 1.- Returns all the unsold items.
    function fetchMarketItems() public view returns (MarketItem[] memory){
        // It's public and view to access from our front end and also because there is no transaction related.
        // It will returns an array of items.

        uint itemCount = _itemIds.current(); // Get the number of items in the market.
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current(); // Get the number of items that are not sold.
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount); // Create an array of items.
        // Loop over the number of items that have been created
        for (uint i = 0; i < itemCount; i++){
            // Check if this item is unsold. And know it by the owner of the item. If the owner is 0 (as address), we know that this item is not sold yet.
            if(idToMarketItem[i+1].owner == address(0)){
                uint currentId = idToMarketItem[i+1].itemId; // Get the id of the item that we are interacting with.
                MarketItem storage currentItem = idToMarketItem[currentId]; // Get a reference to the item that we want to insert on the array.
                items[currentIndex] = currentItem; // Insert the item on the array.
                currentIndex += 1; // Increment the current index of the array
            }
        }
        return items;
    }

    // 2.- Returns only the items that I've purschased.
    function fetchMyNFTs() public view returns (MarketItem[] memory){
        uint totalItemCount = _itemIds.current(); // Get the number of items in the market.
        uint itemCount = 0;
        uint curentIndex = 0; // Get the current index of the array.

        // Get the number of items that we have purchased.
        for (uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i+1].owner == msg.sender){
                itemCount += 1; // Inrease the itemCount for those items that the user has purshased.
            }
        }

        // Now we can map and loop on that array to populate (get all the data) of this items that we've purshased.
        MarketItem[] memory items = new MarketItem[](itemCount); // Now we can use items to see that items purshased.
        for (uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i+1].owner == msg.sender){ // Check if this item is mine
                uint currentId = idToMarketItem[i+1].itemId; // Get the id of the item that we are interacting with.
                MarketItem storage currentItem = idToMarketItem[currentId]; // Get a reference to the item that we want to insert on the array.
                items[curentIndex] = currentItem; // Insert the item on the array.
                curentIndex += 1; // Increment the current index of the array
            }
        }
         return items;
    }

    // 3.- Returns the items that I've created.
    function fetchItemsCreated() public view returns (MarketItem[] memory){
        // Different as previous functions, we will see if the owner is the msg.seller and not the msg.sender.
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i+1].seller == msg.sender){ // If true, I'm the person who created this item.
                uint currentId = idToMarketItem[i+1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}