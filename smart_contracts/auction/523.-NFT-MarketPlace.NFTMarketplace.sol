// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract NFTMarketplace is ERC721Upgradeable, OwnableUpgradeable {
    struct NFT {
        uint256 id;
        uint256 price;
        uint256 auctionEndTime;
        address seller;
        bool isSold;
        address acceptedToken;
    }

    NFT[] public nfts;
    uint256 public publicTokenId;

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) public highestBids;
    mapping(uint256 => address) public highestBidders;
    mapping (uint => NFT) public listings;

    

    address public tokenAddress;
    uint public feePercent;

    function initialize(
        string memory _name,
        string memory _symbol,
        address _tokenAddress
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        tokenAddress = _tokenAddress;
    }

    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = tokenURI;
    }

    function mint(address _to, string memory _tokenURI) public onlyOwner {
        publicTokenId++;
        _mint(_to, publicTokenId);
        _setTokenURI(publicTokenId, _tokenURI);
    }
    event NFTListed(uint tokenId, address seller, uint price);
    event AuctionCreated(address nftContract, uint256  tokenId, uint256 startingPrice, uint256 auctionEndTime);
    event AuctionEnded(address  nftContract, uint256  tokenId, address  winner, uint256 winningBid);
    event NFTSold(address  nftContract, uint256  tokenId, address  seller, address buyer, uint256 salePrice);

    function listNFT(uint _tokenId, uint _price , uint256 _auctionEndtime, address _acceptedTokens) external {
        require(msg.sender != address(0), "Invalid seller address.");
        require(_price > 0, "Price must be greater than zero.");
        require(listings[_tokenId].id == 0, "NFT is already listed.");
        
        ERC721 nft = ERC721(msg.sender);
        require(nft.ownerOf(_tokenId) == msg.sender, "Seller is not the owner of the NFT.");
        
        listings[_tokenId] = NFTL({
            id: _tokenId,
            price: _price;
            auctionEndTime:_auctionEndtime ;
            seller : msg.sender;
            isSold:  false;
            acceptedToken : _acceptedTokens;
        });
        
        emit NFTListed(_tokenId, msg.sender, _price);
    }

    function buyNFT(uint _tokenId) external payable {
        NFT storage listing = listings[_tokenId];
        require(listing.tokenId > 0, "NFT is not listed for sale.");
        require(listing.isSold == false, "NFT is already sold.");
        require(msg.sender != listing.seller, "Seller cannot buy their own NFT.");
        require(msg.value == listing.price, "Sent value is not equal to the NFT price.");
        
        listing.isSold = true;
        
        ERC721 nft = ERC721(listing.seller);
        nft.safeTransferFrom(listing.seller, msg.sender, _tokenId);
        feePercent=2;
        
        uint fee = (listing.price * feePercent) / 100;
        uint sellerProceeds = listing.price - fee;
        
        payable(listing.seller).transfer(sellerProceeds);
        payable(msg.sender).transfer(fee);
        
        emit NFTSold(_tokenId, listing.seller, msg.sender, listing.price, fee);
    }
    struct Auction {
        uint256 nftId;           // ID of the NFT being auctioned
        address seller;         // Address of the seller
        uint256 startingPrice;  // Starting price for the auction
        uint256 currentBid;     // Current highest bid
        address currentBidder;  // Address of the current highest bidder
        uint256 auctionEndTime; // Timestamp of when the auction ends
        bool ended;             // Whether the auction has ended or not
    }
    
    
    mapping(address => mapping(uint256 => Auction)) public auctions;
    
    
    
    
    
    function createFixedPriceSale(address nftContract, uint256 tokenId, uint256 price) external {
       
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "You do not own this NFT");
        
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        
        emit NFTSold(nftContract, tokenId, msg.sender, address(this), price);
    }
    
    
    function createAuction(address nftContract, uint256 tokenId, uint256 startingPrice, uint256 auctionDuration) external {
        
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "You do not own this NFT");
        
        require(auctionDuration >= 60, "Auction duration must be at least one minute");
        
        uint256 auctionEndTime = block.timestamp + auctionDuration;
        
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
      
        auctions[nftContract][tokenId] = Auction({
            nftId: tokenId,
            seller: msg.sender,
            startingPrice: startingPrice,
            currentBid: startingPrice,
            currentBidder: address(0),
            auctionEndTime: auctionEndTime,
            ended: false
        });
       
        emit AuctionCreated(nftContract, tokenId, startingPrice, auctionEndTime);
    }
        event NewBid(
        address indexed bidder,
        uint256 value,
        uint256 indexed auctionIndex
    );

    function bidOnAuction(
        uint256 _index,
        uint256 tokenId,
        string memory _tokenURI
    ) public payable {
        NFT storage nft = listings[tokenId];
        require(
            msg.value > nft.price,
            "Bid value should be greater than current price."
        );
        require(
            msg.value > highestBids[_index],
            "Bid value should be greater than highest bid."
        );

        if (highestBidders[_index] != address(0)) {
            payable(highestBidders[_index]).transfer(highestBids[_index]);
        }

        highestBids[_index] = msg.value;
        highestBidders[_index] = msg.sender;

        emit NewBid(msg.sender, msg.value, _index);
        _setTokenURI(tokenId, _tokenURI);
    }
}

    
 
