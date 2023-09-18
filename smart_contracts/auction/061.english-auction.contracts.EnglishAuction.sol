// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import "hardhat/console.sol"; // used in testing chains

error EnglishAuction__InvalidAddress();
error EnglishAuction__NotOwner(address nftAddress, uint256 tokenId, address seller);
error EnglishAuction__NotApproved(address nftAddress, uint256 tokenId, address owner);

error EnglishAuction__AuctionCreated(address nftAddress, uint256 tokenId);
error EnglishAuction__AuctionNotInProgress(address nftAddress, uint256 tokenId);
error EnglishAuction__AuctionNotEnded(address nftAddress, uint256 tokenId);

error EnglishAuction__InsufficientAmount(address nftAddress, uint256 tokenId, uint256 price);

error EnglishAuction__SellerIsTheBidder(address seller, address bidder);
error EnglishAuction__CallerIsNotTheSeller(address caller, address seller);
error EnglishAuction__AuctionIsNotOverYet(uint256 endingAt);

error EnglishAuction__TransactionFailed();
error EnglishAuction__NotAuctionSeller(address seller);

// ---

/**
 * @title Simple English Auction Contract
 * @author Al-Qa'qa'
 * @notice This contract works like a sinple mutlisig wallet
 */
contract EnglishAuction {
  /// @dev The available state of the auction
  enum AuctionStatus {
    NOT_CREATED,
    IN_PROGRESS,
    ENDED
  }

  event AuctionCreated(address indexed nftAddress, uint256 indexed tokenId);

  event NewBid(address indexed nftAddress, uint256 indexed tokenId, uint256 price);

  event AuctionEnded(address indexed nftAddress, uint256 indexed tokenId, address winner);

  /// @notice Bidder parameters
  struct Bidder {
    address bidder;
    uint256 value;
  }

  /// @notice Auction parameters
  struct Auction {
    address seller;
    address nftAddress;
    uint256 tokenId;
    uint256 startingAt;
    uint256 endingAt;
    uint256 startingPrice;
    uint256 highestBid;
    address highestBidder;
    Bidder[] bidders;
    AuctionStatus status;
  }

  /// @notice NFT address -> tokenId -> Auction Object
  mapping(address => mapping(uint256 => Auction)) public auctions;

  modifier isAuctionNotCreated(address _nftAddress, uint256 _tokenId) {
    Auction memory auction = auctions[_nftAddress][_tokenId];
    if (auction.status != AuctionStatus.NOT_CREATED) {
      // You can't revert with the auction params since they will give the default values not the values gived by the connector
      revert EnglishAuction__AuctionCreated(_nftAddress, _tokenId);
    }
    _;
  }

  modifier isAuctionInProgress(address _nftAddress, uint256 _tokenId) {
    Auction memory auction = auctions[_nftAddress][_tokenId];
    if (auction.status != AuctionStatus.IN_PROGRESS) {
      // You can't revert with the auction params since they will give the default values not the values gived by the connector
      revert EnglishAuction__AuctionNotInProgress(_nftAddress, _tokenId);
    }
    _;
  }

  // You don't need this modifier but we will leave it
  //
  // modifier isAuctionEnded(address _nftAddress, uint256 _tokenId) {
  //   Auction memory auction = auctions[_nftAddress][_tokenId];
  //   if (auction.status != AuctionStatus.ENDED) {
  //     // You can't revert with the auction params since they will give the default values not the values gived by the connector
  //     revert EnglishAuction__AuctionNotEnded(_nftAddress, _tokenId);
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
   * @param _tokenId Token ID of the item being auctioned
   * @param _startingPrice Auction starting price
   * @param _duration How long the auction takes to end
   */
  function createAuction(
    address _nftAddress,
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _duration
  ) external {
    // Check that nftAddress is valid
    if (_nftAddress == address(0)) {
      revert EnglishAuction__InvalidAddress();
    }

    // check that `msg.sender` owns this NFT item
    if (IERC721(_nftAddress).ownerOf(_tokenId) != msg.sender) {
      revert EnglishAuction__NotOwner(_nftAddress, _tokenId, msg.sender);
    }

    // Check that our contract has an access to this NFT item
    if (
      !(IERC721(_nftAddress).getApproved(_tokenId) == address(this) ||
        IERC721(_nftAddress).isApprovedForAll(msg.sender, address(this)))
    ) {
      revert EnglishAuction__NotApproved(_nftAddress, _tokenId, msg.sender);
    }

    // It is better to check for duration and to make it has minimum value like 1 day

    // If the auction was ended then we will reset it again as the auction should be
    // in `NOT_CREATED` state in order to be opened
    Auction storage auction = auctions[_nftAddress][_tokenId];
    if (auction.status == AuctionStatus.ENDED) {
      auctions[_nftAddress][_tokenId].status = AuctionStatus.NOT_CREATED;
    }

    _createAuction(_nftAddress, _tokenId, _startingPrice, _duration);
  }

  /**
   * @notice Add new bid in the given auction
   *
   * @param _nftAddress ERC721 address
   * @param _tokenId Token ID of the item being auctioned
   */
  function bid(
    address _nftAddress,
    uint256 _tokenId
  ) external payable isAuctionInProgress(_nftAddress, _tokenId) {
    (
      address seller,
      ,
      ,
      ,
      ,
      uint256 startingPrice,
      uint256 highestBid,
      address highestBidder,
      ,

    ) = getAuction(_nftAddress, _tokenId);

    // Check that the seller is not bidder, as he can't buy what he want to sell
    if (seller == msg.sender) {
      revert EnglishAuction__SellerIsTheBidder(seller, msg.sender);
    }

    // Check to see if this is the first bidder or not
    if (highestBidder == address(0)) {
      if (msg.value < startingPrice)
        revert EnglishAuction__InsufficientAmount(_nftAddress, _tokenId, msg.value);
      _addNewBidder(_nftAddress, _tokenId, msg.sender, msg.value);

      // existing the function to not send transaction to ZeroAddress and to prevent dublicate adding new Bidder
      return;
    }

    // Check that the value is greater than the higestBid value
    if (msg.value < highestBid) {
      revert EnglishAuction__InsufficientAmount(_nftAddress, _tokenId, msg.value);
    }

    // console.log(highestBidder.balance);

    // refunded the previous bidder with balance
    (bool success, ) = payable(highestBidder).call{value: highestBid}("");
    if (!success) revert EnglishAuction__TransactionFailed();

    // console.log(highestBidder.balance);

    // Adding new bidder in the auction
    _addNewBidder(_nftAddress, _tokenId, msg.sender, msg.value);
  }

  /**
   * @notice End the auction and transfer item to the highest bidder if existed, and send money to the seller.
   * @dev This function can only be caller by the seller address.
   * @dev It is better to make an automation to call this function once the real time reaches ending time of the
   *      auction using oracle networks like ChainLink, but we kept it simple by making it called by the seller.
   *
   * @param _nftAddress ERC721 address
   * @param _tokenId Token ID of the item being auctioned
   */
  function endAuction(
    address _nftAddress,
    uint256 _tokenId
  ) external payable isAuctionInProgress(_nftAddress, _tokenId) {
    (
      address seller,
      ,
      ,
      ,
      uint256 endingAt,
      ,
      uint256 highestBid,
      address highestBidder,
      ,

    ) = getAuction(_nftAddress, _tokenId);

    // Check that the seller is the one who want to finish the auction
    if (seller != msg.sender) {
      revert EnglishAuction__CallerIsNotTheSeller(msg.sender, seller);
    }

    // Check that the auction has been ended
    if (endingAt > block.timestamp) {
      revert EnglishAuction__AuctionIsNotOverYet(endingAt);
    }

    // Finish Auction by update its state, and reseting bidders
    _endAuction(_nftAddress, _tokenId);

    // If there is no bidders then we emit `AuctionEnded` event and exit the function
    if (highestBidder == address(0) || highestBid == 0) {
      emit AuctionEnded(_nftAddress, _tokenId, address(0));
      return;
    }

    // Transfer the nft to the highestBidder address if existed
    IERC721(_nftAddress).safeTransferFrom(seller, highestBidder, _tokenId);

    // console.log(seller.balance);

    // Give the seller the higestBid amount if existed
    (bool success, ) = payable(seller).call{value: highestBid}("");
    if (!success) revert EnglishAuction__TransactionFailed();

    // console.log(seller.balance);

    // emit AuctionEnded event
    emit AuctionEnded(_nftAddress, _tokenId, highestBidder);
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
   * @param _duration How long the auction takes to end
   */
  function _createAuction(
    address _nftAddress,
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _duration
  ) private isAuctionNotCreated(_nftAddress, _tokenId) {
    // console.log("New auction will be created");

    auctions[_nftAddress][_tokenId].seller = msg.sender;
    auctions[_nftAddress][_tokenId].nftAddress = _nftAddress;
    auctions[_nftAddress][_tokenId].tokenId = _tokenId;
    auctions[_nftAddress][_tokenId].startingAt = block.timestamp;
    auctions[_nftAddress][_tokenId].endingAt = block.timestamp + _duration;
    auctions[_nftAddress][_tokenId].startingPrice = _startingPrice;
    auctions[_nftAddress][_tokenId].highestBid = 0;
    auctions[_nftAddress][_tokenId].highestBidder = address(0);
    // We added ZeroAddress as a  bidder to initialize the bidders array
    auctions[_nftAddress][_tokenId].bidders.push(Bidder(address(0), 0));
    auctions[_nftAddress][_tokenId].status = AuctionStatus.IN_PROGRESS;

    // You can't initialize `bidders` with an `empty array []`

    emit AuctionCreated(_nftAddress, _tokenId);
  }

  /**
   * @notice Add new bidder to the auction of the given `_nftAddress` and `_tokenId`
   * @dev All check are done on `bid` functions, so we don't neede to check values in this function
   * @dev Refunding the previous bidder (if existed) occuars in `bid` function too
   *
   * @param _nftAddress ERC721 address
   * @param _tokenId Token ID of the item being auctioned
   * @param _bidder Bidder address
   * @param _bidAmount Bidded amount buy the bidder
   */
  function _addNewBidder(
    address _nftAddress,
    uint256 _tokenId,
    address _bidder,
    uint256 _bidAmount
  ) private {
    Auction storage auction = auctions[_nftAddress][_tokenId];

    auction.highestBidder = _bidder;
    auction.highestBid = _bidAmount;
    auction.bidders.push(Bidder(_bidder, _bidAmount));

    emit NewBid(_nftAddress, _tokenId, _bidAmount);
  }

  /**
   * @notice Ending a specific auction by reseting bidders and update state to `ENDED`
   * @dev This function only ends an auction by updating its values, transfereing money, and NFTs
   *      is done in public `endAuction` function
   *
   * @param _nftAddress ERC721 address
   * @param _tokenId Token ID of the item being auctioned
   */
  function _endAuction(address _nftAddress, uint256 _tokenId) private {
    Auction storage auction = auctions[_nftAddress][_tokenId];
    auction.status = AuctionStatus.ENDED;

    // We don't have to remove the first element as the first element is AddressZero by default
    while (auction.bidders.length > 1) {
      auction.bidders.pop();
    }
  }

  ///////////////////////////////////////////////
  /////// Getter, View, and Pure function ///////
  ///////////////////////////////////////////////

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
   * @return highestBid Highest value offered for buying the item
   * @return highestBidder The wallet that the highestBid
   * @return bidders Array of all bidders that participate in the auction
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
      uint256 highestBid,
      address highestBidder,
      Bidder[] memory bidders,
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
      auction.highestBid,
      auction.highestBidder,
      auction.bidders,
      auction.status
    );
  }
}
