// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Triptcip is
  ERC721Burnable,
  ERC721URIStorage,
  Ownable,
  Pausable,
  ReentrancyGuard
{
  using Counters for Counters.Counter;

  event CreateToken(
    uint256 timestamp,
    address indexed owner,
    uint256 indexed tokenId,
    uint256 royalty
  );

  event AuctionCreate(
    uint256 timestamp,
    address indexed owner,
    uint256 indexed tokenId,
    uint256 reservePrice
  );

  event AuctionPlaceBid(
    uint256 timestamp,
    address indexed owner,
    uint256 indexed tokenId,
    uint256 amount,
    uint256 deadline
  );

  event AuctionClaim(
    uint256 timestamp,
    address indexed owner,
    uint256 indexed tokenId
  );

  struct Bid {
    address bidder;
    uint256 amount;
    uint256 timestamp;
  }

  struct WinningBid {
    uint256 amount;
    address bidder;
  }

  struct Auction {
    address seller;
    uint256 reservePrice;
    bool isClaimed;
    uint256 deadline;
    WinningBid winningBid;
    Bid[] bids;
  }

  address private serviceWallet;

  uint private constant BP_DIVISOR = 10000;
  uint256 private serviceFee;
  mapping(uint256 => uint256) private royaltyFees;

  uint256 private deadlineInSeconds;

  mapping(uint256 => Auction) public auctions;
  mapping(address => bool) private creators;
  mapping(uint256 => address) private tokenMinters;

  Counters.Counter private tokenIdCounter;
  string private baseTokenURI;

  modifier onlyAuctionedToken(uint256 _tokenId) {
    require(auctions[_tokenId].seller != address(0), "Does not exist");
    _;
  }

  modifier onlyEOA() {
    require(msg.sender == tx.origin, "No contract calls");
    _;
  }

  constructor(
    address _serviceWallet,
    uint256 _serviceFee,
    uint256 _deadlineInSeconds,
    address[] memory _creators,
    string memory _baseTokenURI
  ) ERC721("Triptcip", "TRIP") onlyEOA {
    require(_serviceWallet != address(0), "_serviceWallet required");
    require(_serviceFee > 0, "_serviceFee invalid");
    require(_serviceFee < BP_DIVISOR, "_serviceFee invalid");

    baseTokenURI = _baseTokenURI;
    serviceWallet = _serviceWallet;
    serviceFee = _serviceFee;
    deadlineInSeconds = _deadlineInSeconds;

    // Setup initial creators
    for (uint i = 0; i < _creators.length; i++) {
      creators[_creators[i]] = true;
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function updateBaseTokenURI(string memory _baseURI) public onlyOwner {
    baseTokenURI = _baseURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function getMinter(uint256 _tokenId) external view returns (address) {
    return tokenMinters[_tokenId];
  }

  function getRoyalty(uint256 _tokenId) external view returns (uint256) {
    return royaltyFees[_tokenId];
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function addCreator(address _address) public onlyOwner {
    creators[_address] = true;
  }

  function removeCreator(address _address) public onlyOwner {
    creators[_address] = false;
  }

  function bulkAddCreators(address[] memory _creators) public onlyOwner {
    for (uint i = 0; i < _creators.length; i++) {
      creators[_creators[i]] = true;
    }
  }

  function createToken(uint256 _royalty) public onlyEOA returns (uint256) {
    require(creators[msg.sender] == true, "Not a creator");
    require(_royalty < BP_DIVISOR - serviceFee, "_royalty invalid");

    tokenIdCounter.increment();

    uint256 newTokenId = tokenIdCounter.current();
    _mint(msg.sender, newTokenId);

    royaltyFees[newTokenId] = _royalty;
    tokenMinters[newTokenId] = msg.sender;

    emit CreateToken(block.timestamp, msg.sender, newTokenId, _royalty);

    return newTokenId;
  }

  function auctionCreate(uint256 _tokenId, uint256 _reservePrice)
    public
    onlyEOA
  {
    Auction storage auction = auctions[_tokenId];

    require(_reservePrice > 0, "`_reservePrice` required");
    require(auction.seller == address(0), "Duplicate");
    require(ERC721.ownerOf(_tokenId) == msg.sender, "Not the owner");

    auction.seller = msg.sender;
    auction.reservePrice = _reservePrice;

    emit AuctionCreate(block.timestamp, msg.sender, _tokenId, _reservePrice);
  }

  function auctionPlaceBid(uint256 _tokenId)
    public
    payable
    onlyAuctionedToken(_tokenId)
    onlyEOA
    nonReentrant
  {
    Auction storage auction = auctions[_tokenId];

    require(msg.value > auction.reservePrice, "Bid too low");
    require(msg.value > auction.winningBid.amount, "Bid too low");
    uint256 deadline = auction.deadline;
    require(block.timestamp < deadline || deadline == 0, "Auction is over");

    // This means, it's a fresh auction, no one has bid on it yet.
    if (auction.deadline == 0) {
      // Start the deadline, it's set to NOW + 24 hours in seconds (86400)
      // Deadline should prob be a contract level constant, or configurable here
      auction.deadline = block.timestamp + deadlineInSeconds;
    } else if (auction.deadline - block.timestamp <= 900) {
      // If within 15 minutes of expiry, extend with another 15 minutes
      auction.deadline = auction.deadline + 900; // TODO: move this to a contract level constant
    }

    uint256 previousBids = auction.bids.length;

    auction.bids.push(Bid(msg.sender, msg.value, block.timestamp));
    auction.winningBid.amount = msg.value;
    auction.winningBid.bidder = msg.sender;

    // Refund previous bid
    if (previousBids > 0) {
      address previousBidder = auction.bids[previousBids - 1].bidder;
      uint256 previousBid = auction.bids[previousBids - 1].amount;

      previousBidder.call{value: previousBid}("");
    }

    emit AuctionPlaceBid(
      block.timestamp,
      msg.sender,
      _tokenId,
      msg.value,
      auction.deadline
    );
  }

  function auctionClaim(uint256 _tokenId)
    public
    onlyAuctionedToken(_tokenId)
    nonReentrant
  {
    Auction storage auction = auctions[_tokenId];

    require(block.timestamp > auction.deadline, "Auction not over");

    auction.isClaimed = true;

    uint256 salePrice = auction.winningBid.amount;
    uint256 serviceFeeAmount = (salePrice * serviceFee) / BP_DIVISOR;
    uint256 royaltyFeeAmount = (salePrice * royaltyFees[_tokenId]) / BP_DIVISOR;

    // Pay the platform
    serviceWallet.call{value: serviceFeeAmount}("");

    // Pay the royalty
    tokenMinters[_tokenId].call{value: royaltyFeeAmount}("");

    // Pay the seller
    auction.seller.call{value: salePrice - serviceFeeAmount - royaltyFeeAmount}(
      ""
    );

    address winner = auction.winningBid.bidder;

    delete auctions[_tokenId];

    _safeTransfer(ownerOf(_tokenId), winner, _tokenId, "");

    emit AuctionClaim(block.timestamp, msg.sender, _tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);

    require(auctions[tokenId].seller == address(0), "In auction");
    require(!paused(), "Paused");
  }
}
