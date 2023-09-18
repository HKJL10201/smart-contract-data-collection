// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractaddress;


    constructor (address marketplaceaddress) ERC721 ("Alireza's digital marketplace" , "ADM") {
        contractaddress = marketplaceaddress;
    }

    function createToken(string memory tokenURI) public returns (uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(contractaddress, true);
        return newItemId;
    }
}
contract NFTMarket is ReentrancyGuard {
    
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    address payable owner;
    uint256 listingPrice = 0.1 ether;
  
   constructor() {
    owner = payable(msg.sender);
   }


    struct MarketItem {
    uint itemId;
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable owner;
    uint256 price;
  }
  mapping (uint256 => MarketItem) private IdToMarketItem;

   event MarketItemCreated (
    uint indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price
  );

  function CreateMarketItem(address nftContract, uint256 tokenId, uint256 price) public payable nonReentrant {
      
      require (price > 0 ,"The price must be greater than zero");
      require(msg.value == listingPrice, "Price must be equal to listing price");

      _itemIds.increment();
      
        uint256 itemId = _itemIds.current();      

        IdToMarketItem[itemId] = MarketItem(itemId, nftContract, tokenId, payable(msg.sender), payable(address(0)),price);

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(itemId,nftContract,tokenId,msg.sender,address(0),price);
        
 }
 
 
  function createMarketSale(address nftContract,uint256 itemId) public payable nonReentrant {
    
    uint price = IdToMarketItem[itemId].price;
    uint tokenId = IdToMarketItem[itemId].tokenId;
    require(msg.value == price, "Please submit the  price in order to the purchase");
    IdToMarketItem[itemId].seller.transfer(msg.value);
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    IdToMarketItem[itemId].owner = payable(msg.sender);
    _itemsSold.increment();
    payable(owner).transfer(listingPrice);
  }

  function fetchMarketItem() public view returns(MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    
    for (uint i = 0; i < itemCount; i++) {
      if (IdToMarketItem[i + 1].owner == address(0)) {
        uint currentId = i + 1;
        MarketItem storage currentItem = IdToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (IdToMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }

    }

   MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (IdToMarketItem[i + 1].owner == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = IdToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
   
    return items;
  }
}
