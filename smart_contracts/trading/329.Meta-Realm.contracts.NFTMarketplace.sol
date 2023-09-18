// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listingPrice = 1 ether;
    address payable owner;

    mapping(uint256 => Land) private LandItemsMapping;

    struct Land {
      uint256 tokenId;
      address payable seller;
      address payable owner;
      string uri;
      string landName;
      uint256 lat;
      uint256 lon;
      uint256 price;
      bool sold;
    }

    event MarketItemCreated (
      uint256 indexed tokenId,
      address seller,
      address owner,
      string uri,
      string landName,
      uint256 lat,
      uint256 lon,
      uint256 price,
      bool sold
    );

    constructor() ERC721("Metaverse Tokens", "METT") {
      owner = payable(msg.sender);
    }






    // ** TOKEN CREATION START **
    /* Mints a token and lists it in the marketplace */
    function CreateLandToken(string memory tokenURI, string memory landName, uint256 lat, uint256 lon, uint256 price) public payable returns (uint) 
    {
      _tokenIds.increment();
      uint256 newTokenId = _tokenIds.current();

      _mint(msg.sender, newTokenId);
      _setTokenURI(newTokenId, tokenURI);
      createMarketItem(newTokenId, tokenURI ,landName, lat, lon, price  );
      return newTokenId;
    }

    function createMarketItem( uint256 tokenId,string memory uri,string memory landName, uint256 lat, uint256 lon ,uint256 price ) private 
    {
      require(price > 0, "Price must be at least 1 wei");
      require(msg.value == listingPrice, "Price must be equal to listing price");

      LandItemsMapping[tokenId] =  Land(
        tokenId,
        payable(msg.sender), //seller
        payable(address(this)), //owner
        uri,
        landName,
        lat,
        lon,
        price,
        false
      );

      _transfer(msg.sender, address(this), tokenId);
      emit MarketItemCreated(
        tokenId,
        msg.sender,
        address(this),
        uri,
        landName,
        lat,
        lon,
        price,
        false
      );
    }
    // ** TOKEN CREATION END **









    /* allows someone to resell a token they have purchased */
    function SellYourLandToken(uint256 tokenId, uint256 price) public payable 
    {
      require(LandItemsMapping[tokenId].owner == msg.sender, "Only item owner can perform this operation");
      require(msg.value == listingPrice, "Price must be equal to listing price");
      LandItemsMapping[tokenId].sold = false;
      LandItemsMapping[tokenId].price = price;
      LandItemsMapping[tokenId].seller = payable(msg.sender);
      LandItemsMapping[tokenId].owner = payable(address(this));
      _itemsSold.decrement();

      _transfer(msg.sender, address(this), tokenId);
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function BuyLandToken( uint256 tokenId ) public payable 
    {
      uint price = LandItemsMapping[tokenId].price;
      address seller = LandItemsMapping[tokenId].seller;
      require(msg.value == price * 10**18 , "Please submit the asking price in order to complete the purchase");
      LandItemsMapping[tokenId].owner = payable(msg.sender);
      LandItemsMapping[tokenId].sold = true;
      LandItemsMapping[tokenId].seller = payable(address(0));
      _itemsSold.increment();
      _transfer(address(this), msg.sender, tokenId);
      payable(owner).transfer(listingPrice);
      payable(seller).transfer(msg.value);
    }













    // ************** utility functions **************
    /* Returns owner of the contract or metavers */
    function getOwnerOfMeta() public view returns (address) 
    {
      return owner;
    }

    /* Updates the listing price of the contract */
    function updateListingPrice(uint _listingPrice) public payable 
    {
      require(owner == msg.sender, "Only marketplace owner can update listing price.");
      listingPrice = _listingPrice;
    }

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) 
    {
      return listingPrice;
    }

    /* Returns the full details of the corresponding tokenid */
    function getTokenDetails(uint256 _tokenId) public view returns(Land memory)
    {
      return LandItemsMapping[_tokenId];
    }

    /* fetches all available land tokens   */
    function fetchAllTokens() public view returns (Land[] memory) 
    {
      uint totalItemCount = _tokenIds.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
          itemCount += 1;
      }

      Land[] memory items = new Land[](itemCount);

      for (uint i = 0; i < totalItemCount; i++) 
      {
          uint currentId = i + 1;
          Land storage currentItem = LandItemsMapping[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        
      }
      return items;
    }







    /* Returns all unsold market items */
    function fetchMarketItems() public view returns (Land[] memory) 
    {
      uint itemCount = _tokenIds.current();
      uint unsoldItemCount = _tokenIds.current() - _itemsSold.current();
      uint currentIndex = 0;

      Land[] memory items = new Land[](unsoldItemCount);
      for (uint i = 0; i < itemCount; i++) {
        if (LandItemsMapping[i + 1].owner == address(this)) {
          uint currentId = i + 1;
          Land storage currentItem = LandItemsMapping[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    /* Returns only items that a user has purchased */
    function fetchMyNFTs(address _owner_address) public view returns (Land[] memory) 
    {
      uint totalItemCount = _tokenIds.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (LandItemsMapping[i + 1].owner == _owner_address) {
          itemCount += 1;
        }
      }

      Land[] memory items = new Land[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (LandItemsMapping[i + 1].owner == _owner_address) {
          uint currentId = i + 1;
          Land storage currentItem = LandItemsMapping[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    /* Returns only items a user has listed */
    function fetchItemsListed() public view returns (Land[] memory) 
    {
      uint totalItemCount = _tokenIds.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (LandItemsMapping[i + 1].seller == msg.sender) {
          itemCount += 1;
        }
      }

      Land[] memory items = new Land[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (LandItemsMapping[i + 1].seller == msg.sender) {
          uint currentId = i + 1;
          Land storage currentItem = LandItemsMapping[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }
}
