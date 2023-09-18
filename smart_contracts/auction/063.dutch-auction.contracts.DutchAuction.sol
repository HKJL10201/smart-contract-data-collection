// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import "hardhat/console.sol"; // used in testing chains

// ---

error DutchAuction__InvalidAddress();
error DutchAuction__NotOwner(address nftAddress, uint256 tokenId, address seller);
error DutchAuction_NotApproved(address nftAddress, uint256 tokenId, address owner);

error DutchAuction__FloorPriceLessThanZero(
  uint256 startingPrice,
  uint256 discountRate,
  uint256 duration
);

error DutchAuction__AuctionCreated(address nftAddress, uint256 tokenId);
error DutchAuction__AuctionNotInProgress(address nftAddress, uint256 tokenId);
error DutchAuction__AuctionNotEnded(address nftAddress, uint256 tokenId);

error DutchAuction__InsufficientAmount(address nftAddress, uint256 tokenId, uint256 price);

error DutchAuction__TransactionFailed();
error DutchAuction__NotAuctionSeller(address seller);

// ---

/**
 * @title Simple Dutch Auction Contract
 * @author Al-Qa'qa'
 * @notice This contract works like a sinple mutlisig wallet
 */
contract DutchAuction {
  /// @dev The available state of the auction
  enum AuctionStatus {
    NOT_CREATED,
    IN_PROGRESS,
    ENDED
  }

  event AuctionCreated(address indexed nftAddress, uint256 indexed tokenId);

  event AuctionEnded(address indexed nftAddress, uint256 indexed tokenId, address winner);

  uint256 private constant DURATION = 7 days;

  /// @notice Auction parameters
  struct Auction {
    address seller;
    address nftAddress;
    uint256 tokenId;
    uint256 startingAt;
    uint256 endingAt;
    uint256 startingPrice;
    uint256 discountRate;
    AuctionStatus status;
  }

  /// @notice NFT address -> tokenId -> Auction Object
  mapping(address => mapping(uint256 => Auction)) public auctions;

  modifier isAuctionNotCreated(address _nftAddress, uint256 _tokenId) {
    Auction memory auction = auctions[_nftAddress][_tokenId];
    if (auction.status != AuctionStatus.NOT_CREATED) {
      // You can't revert with the auction params since they will give the default values not the values gived by the connector
      revert DutchAuction__AuctionCreated(_nftAddress, _tokenId);
    }
    _;
  }

  modifier isAuctionInProgress(address _nftAddress, uint256 _tokenId) {
    Auction memory auction = auctions[_nftAddress][_tokenId];
    if (auction.status != AuctionStatus.IN_PROGRESS) {
      // You can't revert with the auction params since they will give the default values not the values gived by the connector
      revert DutchAuction__AuctionNotInProgress(_nftAddress, _tokenId);
    }
    _;
  }

  // You don't need this modifier but we will leave it
  //
  // modifier isAuctionEnded(address _nftAddress, uint256 _tokenId) {
  //   Auction memory auction = auctions[_nftAddress][_tokenId];
  //   if (auction.status != AuctionStatus.ENDED) {
  //     // You can't revert with the auction params since they will give the default values not the values gived by the connector
  //     revert DutchAuction__AuctionNotEnded(_nftAddress, _tokenId);
  //   }
  //   _;
  // }

  ///////////////////////////////////////////////
  //////// external and public function /////////
  ///////////////////////////////////////////////

  /**
   * @notice Create new auction for a given NFT item
   * @dev Only the owner of this NFT can list the item
   *
   * @param _nftAddress ERC721 Address
   * @param _tokenId NFT item token id
   * @param _startingPrice Auction starting price
   * @param _discountRate The amount will be decreased every second from the starting price
   */
  function createAuction(
    address _nftAddress,
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _discountRate
  ) external {
    // Check that nftAddress is valid
    if (_nftAddress == address(0)) {
      revert DutchAuction__InvalidAddress();
    }

    // check that `msg.sender` owns this NFT item
    if (IERC721(_nftAddress).ownerOf(_tokenId) != msg.sender) {
      revert DutchAuction__NotOwner(_nftAddress, _tokenId, msg.sender);
    }

    // Check that our contract has an access to this NFT item
    if (
      !(IERC721(_nftAddress).getApproved(_tokenId) == address(this) ||
        IERC721(_nftAddress).isApprovedForAll(msg.sender, address(this)))
    ) {
      revert DutchAuction_NotApproved(_nftAddress, _tokenId, msg.sender);
    }

    //  Check that discount rate is set so that not to make price less that zero
    if (_startingPrice < _discountRate * DURATION) {
      revert DutchAuction__FloorPriceLessThanZero(_startingPrice, _discountRate, DURATION);
    }

    // If the auction was ended then we will reset it again as the auction should be
    // in `NOT_CREATED` state in order to be opened
    Auction storage auction = auctions[_nftAddress][_tokenId];
    if (auction.status == AuctionStatus.ENDED) {
      auctions[_nftAddress][_tokenId].status = AuctionStatus.NOT_CREATED;
    }

    _createAuction(_nftAddress, _tokenId, _startingPrice, _discountRate);
  }

  /**
   * @notice Buying item that is in auction
   *
   * @param _nftAddress ERC721 address
   * @param _tokenId token id of an item to be bought
   */
  function buyItem(
    address _nftAddress,
    uint256 _tokenId
  ) external payable isAuctionInProgress(_nftAddress, _tokenId) {
    (address seller, , , , , , , ) = getAuction(_nftAddress, _tokenId);

    uint256 price = getPrice(_nftAddress, _tokenId);

    if (msg.value < price) {
      revert DutchAuction__InsufficientAmount(_nftAddress, _tokenId, msg.value);
    }

    //
    // Refunding the buyer if he pay with price more than required
    if (price < msg.value) {
      (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - price}("");
      if (!refundSuccess) revert DutchAuction__TransactionFailed();
    }

    // console.log("Buyer balance after refunding : ", msg.sender.balance);

    // Transfere the NFT from the seller to the buyer
    IERC721(_nftAddress).safeTransferFrom(seller, msg.sender, _tokenId);

    // Transfere the money to the seller
    (bool success, ) = payable(seller).call{value: price}("");
    if (!success) revert DutchAuction__TransactionFailed();

    // End the auction
    auctions[_nftAddress][_tokenId].status = AuctionStatus.ENDED;

    emit AuctionEnded(_nftAddress, _tokenId, msg.sender);
  }

  /**
   * @notice Cancel the auction manually by the seller
   *
   * @param _nftAddress ERC721 address
   * @param _tokenId token id of the listed item on the auction
   */
  function cancelAuction(
    address _nftAddress,
    uint256 _tokenId
  ) external isAuctionInProgress(_nftAddress, _tokenId) {
    (address seller, , , , , , , ) = getAuction(_nftAddress, _tokenId);
    if (seller != msg.sender) {
      revert DutchAuction__NotAuctionSeller(seller);
    }

    auctions[_nftAddress][_tokenId].status = AuctionStatus.ENDED;

    emit AuctionEnded(_nftAddress, _tokenId, address(0));
  }

  ///////////////////////////////////////////////
  //////// private and internal function ////////
  ///////////////////////////////////////////////

  /**
   * @notice Private method that has the logic of creating an auction
   * @dev the auction status should be `NOT_CREATED` in order to create the auction successfully
   *
   * @param _nftAddress ERC721 address
   * @param _tokenId token id of the item to be listed
   * @param _startingPrice the price at which the auction will starts
   * @param _discountRate amount of money that will be decreased every second from the startingPrice
   */
  function _createAuction(
    address _nftAddress,
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _discountRate
  ) private isAuctionNotCreated(_nftAddress, _tokenId) {
    // console.log("New auction will be created");

    auctions[_nftAddress][_tokenId].seller = msg.sender;
    auctions[_nftAddress][_tokenId].nftAddress = _nftAddress;
    auctions[_nftAddress][_tokenId].tokenId = _tokenId;
    auctions[_nftAddress][_tokenId].startingAt = block.timestamp;
    auctions[_nftAddress][_tokenId].endingAt = block.timestamp * DURATION;
    auctions[_nftAddress][_tokenId].startingPrice = _startingPrice;
    auctions[_nftAddress][_tokenId].discountRate = _discountRate;
    auctions[_nftAddress][_tokenId].status = AuctionStatus.IN_PROGRESS;

    emit AuctionCreated(_nftAddress, _tokenId);
  }

  ///////////////////////////////////////////////
  /////// Getter, View, and Pure function ///////
  ///////////////////////////////////////////////

  /**
   * @notice Get the current price of the listed item on auction
   *
   * @param _nftAddress ERC721 address
   * @param _tokenId token of the listed item in the auction
   */
  function getPrice(
    address _nftAddress,
    uint256 _tokenId
  ) public view isAuctionInProgress(_nftAddress, _tokenId) returns (uint256) {
    (
      ,
      ,
      ,
      // seller
      // nftAddress
      // tokenId
      uint256 startingAt, // endintAt
      ,
      uint256 startingPrice,
      uint256 discountRate,

    ) = getAuction(_nftAddress, _tokenId);
    uint256 timeElapsed = block.timestamp - startingAt;
    uint256 discount = discountRate * timeElapsed;
    return startingPrice - discount;
  }

  /**
   * @notice Getting all information about a given auction by giving `nftAddress` and `tokenId`
   * @dev if there is no listed auction of this nftAddress and tokenId, all returned value will be the default
   *
   * @param _nftAddress ERC721 address
   * @param _tokenId token of the listed item in the auction
   * @return seller the address that listed the item
   * @return nftAddress ERC721 address
   * @return tokenId token if the listed item in the auction
   * @return startingAt starting data of the auction
   * @return endingAt ending data of the auction
   * @return startingPrice the price at which the auction starts
   * @return discountRate discount rate of the price
   * @return status auction status
   */
  function getAuction(
    address _nftAddress,
    uint256 _tokenId
  )
    public
    view
    returns (
      address seller,
      address nftAddress,
      uint256 tokenId,
      uint256 startingAt,
      uint256 endingAt,
      uint256 startingPrice,
      uint256 discountRate,
      AuctionStatus status
    )
  {
    Auction storage auction = auctions[_nftAddress][_tokenId];
    return (
      auction.seller,
      auction.nftAddress,
      auction.tokenId,
      auction.startingAt,
      auction.endingAt,
      auction.startingPrice,
      auction.discountRate,
      auction.status
    );
  }

  /// @notice Get auction duracation (7 days)
  function getDuration() public pure returns (uint256) {
    return DURATION;
  }
}
