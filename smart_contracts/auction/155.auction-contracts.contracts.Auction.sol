// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Auction is ERC721URIStorage {
    //, IERC721Receiver {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;
    address payable owner;
    uint private maxBidsAuction;
    mapping(uint256 => ProductAuction) productAuctions;
    uint256 listPrice;

    //Flat structure related to Product, Bid and Auction
    struct ProductAuction {
        uint256 productTokenId;
        address payable seller;
        address lastBidder;
        uint256 bestPrice;
        uint bidPosition;
        bool currentlyListed;
    }

    //Events updates about the Auction
    event AuctionInitialized(
        uint256 indexed tokenId,
        uint256 minPrice,
        address seller,
        bool currentlyListed
    );

    event AuctionFinished(
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price
    );

    constructor() ERC721("Auction", "AUCT") {
        owner = payable(msg.sender);
        maxBidsAuction = 10;
        listPrice = 0.0001 ether;
    }

    //Product Creation
    function createProductToken(string memory tokenURI, address seller) public {
        require(owner == msg.sender, "Only owner can create token");
        //Increment the tokenId counter, which is keeping track of the number of minted NFTs
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        //Mint the NFT with newTokenId to the administrator wallet
        //and approve contract to transfer on its behalf
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        _approve(address(this), newTokenId);
        createProductAuction(newTokenId, seller);
    }

    function createProductAuction(uint256 tokenId, address seller) private {
        //Update the mapping of tokenId's to Token details, useful for retrieval functions
        productAuctions[tokenId] = ProductAuction(
            tokenId,
            payable(seller),
            payable(seller),
            0,
            0,
            false
        );
    }

    function initializeAuction(
        uint tokenId,
        uint256 initialPrice
    ) public payable {
        require(owner == msg.sender, "Only owner can initialize auction");
        require(
            msg.value == listPrice,
            "Amount for listing price is different"
        );
        //checking if auction has been initialized
        require(
            productAuctions[tokenId].currentlyListed == false,
            "This auction has already been started"
        );
        //asserting the initialPrice isn't negative
        require(initialPrice > 0, "the price is invalid");

        //updating struct to be listed
        productAuctions[tokenId].bestPrice = initialPrice;
        productAuctions[tokenId].currentlyListed = true;

        emit AuctionInitialized(
            tokenId,
            initialPrice,
            productAuctions[tokenId].seller,
            true
        );
    }

    function bid(
        uint tokenId,
        uint256 bidPrice,
        address bidder
    ) public payable {
        require(owner == msg.sender, "Only owner can access this method");
        //validates if The tokenId does exists and if it's listed
        require(
            productAuctions[tokenId].currentlyListed,
            "No Listed Product found"
        );
        //Check if the new Bid price is higher than the last one
        require(
            bidPrice > productAuctions[tokenId].bestPrice,
            "the price must be higher than the last Bid"
        );

        productAuctions[tokenId].bestPrice = bidPrice;
        productAuctions[tokenId].lastBidder = payable(bidder);
        productAuctions[tokenId].bidPosition += 1;

        if (productAuctions[tokenId].bidPosition == maxBidsAuction) {
            executeSale(tokenId);
        }
    }

    function executeSale(uint256 tokenId) private {
        //Transfer the token to the new owner(already approved)
        _transfer(owner, productAuctions[tokenId].lastBidder, tokenId);

        //Transfer the listing fee to the marketplace creator
        payable(owner).transfer(listPrice);

        productAuctions[tokenId].currentlyListed = false;

        emit AuctionFinished(
            tokenId,
            productAuctions[tokenId].seller,
            productAuctions[tokenId].lastBidder,
            productAuctions[tokenId].bestPrice
        );
    }

    //Gets and Updates
    function getCurrentTokenId() public view returns (string memory) {
        return _tokenIds.current().toString();
    }

    function getAuction(
        uint256 tokenId
    ) public view returns (ProductAuction memory) {
        return productAuctions[tokenId];
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function updateListPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    function getMaxBidAuction() public view returns (uint256) {
        return maxBidsAuction;
    }

    function updateMaxBidNumber(uint256 _maxBidNumber) public payable {
        require(owner == msg.sender, "Only owner can update maxBidNumber");
        maxBidsAuction = _maxBidNumber;
    }
}
