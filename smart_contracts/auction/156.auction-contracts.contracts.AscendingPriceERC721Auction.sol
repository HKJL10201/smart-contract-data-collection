pragma solidity ^0.4.23;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/AuctionComponents/AuctionBase.sol

/**
 * @title AuctionBase
 *
 * @author The AUX Team
 * @notice Base contract for single contract auctions. Assumes a single seller per auction.
 *
 */


contract AuctionBase is Pausable {
  using SafeMath for uint256;

  mapping(uint256 => address) public auctionIdToSeller;

  //Start at 1 to avoid use of 0 which should be reserved for a 'null' auction value;
  uint256 public nextAuctionId = 1;

  /**
   * @dev Throws if called by any account other than the seller for a given auction.
   */
  modifier onlySeller(uint256 auctionId) {
    require(msg.sender == auctionIdToSeller[auctionId]);
    _;
  }

  event AuctionCreated(address indexed createdBy, uint256 indexed auctionId);

  /**
   * @notice Creates an auction with an ID equivalent ot the value of nextAuctionId, then puts the caller's address in the auctionIdToSeller mapping.
   */
  function createEmptyAuction() internal returns (uint256) {
    uint256 thisAuctionId = nextAuctionId;
    nextAuctionId = nextAuctionId.add(1);

    auctionIdToSeller[thisAuctionId] = msg.sender;

    emit AuctionCreated(msg.sender, thisAuctionId);
    return thisAuctionId;
  }

  function transferWinnings(address recipient, uint256 auctionId) internal;
}

// File: contracts/AuctionComponents/FeeCollector.sol

/**
 * @title FeeCollector
 *
 * @author The AUX Team
 * @notice Adds modifiers for requiring fees on function calls
 *
 */


contract FeeCollector is Ownable {
  using SafeMath for uint256;
  uint256 feeBalance = 0;
  /**
   * @dev Throws if called by any account other than the seller for a given auction.
   */
  modifier requiresFee(uint256 feeAmount) {
    require(msg.value >= feeAmount);
    feeBalance = feeBalance.add(feeAmount);
    msg.sender.transfer(msg.value.sub(feeAmount));
    _;
  }

  event FeesWithdrawn(address indexed owner, uint256 indexed withdrawalAmount);

  function withdrawFees() external onlyOwner {
    uint256 feeAmountWithdrawn = feeBalance;
    feeBalance = 0;
    owner.transfer(feeAmountWithdrawn);
    emit FeesWithdrawn(owner, feeAmountWithdrawn);
  }
}

// File: contracts/AuctionComponents/AscendingPriceAuction.sol

/**
 * @title AscendingPriceAuction
 *
 * @author The AUX Team
 * @notice Contract for a single contract "Ascending Price" auction.
 */


contract AscendingPriceAuction is AuctionBase, FeeCollector {
  using SafeMath for uint256;

  mapping(uint256 => uint256) public auctionIdToStartPrice;
  mapping(uint256 => uint256) public auctionIdToMinBidIncrement;
  mapping(uint256 => uint256) public auctionIdToEndBlock;
  mapping(uint256 => uint256) public auctionIdToWinningBid;
  mapping(uint256 => address) public auctionIdToWinningBidder;

  //pendingReturn represents a pool of all outbid refunds and auction proceeds the user has yet to be sent. pendingReturn can be withdrawn by a user by calling the sendReturn function to their own address.
  mapping(address => uint) pendingReturn;

  /**
   * @dev Throws if called before a given auction is over.
   */
  modifier onlyAfterAuctionEnd(uint256 auctionId) {
    require(block.number > auctionIdToEndBlock[auctionId]);
    _;
  }

  /**
   * @dev Throws if called after a given auction is over.
   */
  modifier onlyDuringAuction(uint256 auctionId){
    require(auctionIdToEndBlock[auctionId] >= block.number);
    _;
  }

  event NewHighBid(address indexed highBidder, uint256 highBid, uint256 auctionId);

  /**
   * @notice Should replace the current winning bid and transfer the previously winning bid to the previous winning bidder's pending return pool.
   */
  function bid(uint256 auctionId, uint256 bidAmount) whenNotPaused onlyDuringAuction(auctionId) external payable {
    // Bidder must exist
    require(msg.sender != 0x0);
    // Bid must be at least the current minimum bid.
    require(bidAmount >= getCurrentMinimumBid(auctionId));
    // Bidder must have enough combined value in pending return and the msg.value sent to this function in order to meet the bid amount specified.
    require((msg.value.add(pendingReturn[msg.sender])) >= bidAmount);

    address previousWinningBidder = auctionIdToWinningBidder[auctionId];
    uint256 previousWinningBid = auctionIdToWinningBid[auctionId];

    address seller = auctionIdToSeller[auctionId];

    //Refund previous winning bidder's bid amount to their pending return balance.
    pendingReturn[previousWinningBidder] = pendingReturn[previousWinningBidder].add(previousWinningBid);
    //Rebalance the new bidder's pendingReturn in case they dipped into their pendingReturn to make the bid, or in case they overbid.
    pendingReturn[msg.sender] = pendingReturn[msg.sender].add(msg.value).sub(bidAmount);
    //Rebalance the seller's pendingReturn with the new winningBidAmount.
    pendingReturn[seller] = pendingReturn[seller].add(bidAmount).sub(previousWinningBid);

    //Set the new winning bidder's address and their bid amount.
    auctionIdToWinningBid[auctionId] = bidAmount;
    auctionIdToWinningBidder[auctionId] = msg.sender;

    emit NewHighBid(msg.sender, bidAmount, auctionId);
  }

  /**
   * @notice Allows anyone to transfer the winnings to the winning bidder. By allowing anyone to call this (outside of just the recipient), we can potentially automate the return/claim process.
   */
  function transferWinningsToWinningBidder(uint256 auctionId) whenNotPaused external onlyAfterAuctionEnd(auctionId) {
    require(auctionIdToWinningBidder[auctionId] != 0x0);
    transferWinnings(auctionIdToWinningBidder[auctionId], auctionId);
  }

  /**
   * @notice Allows seller to reclaim their asset if the auction is over and no one has bid on it.
   */
  function transferUnsoldAssetToSeller(uint256 auctionId) whenNotPaused external onlyAfterAuctionEnd(auctionId) {
    require(auctionIdToWinningBidder[auctionId] == 0x0);
    transferWinnings(auctionIdToSeller[auctionId], auctionId);
  }

  /**
   * @notice Allows anyone to send a user their pendingReturn. By allowing anyone to call this (outside of just the recipient), we can potentially automate the return/claim process.
   */
  function sendPendingReturn(address returnRecipient) whenNotPaused external {
    /*require(pendingReturn(msg.sender) >= 0)*/
    returnRecipient.transfer(pendingReturn[returnRecipient]);
    pendingReturn[returnRecipient] = 0;
  }

  function getCurrentMinimumBid(uint256 auctionId) public view returns (uint256) {
    uint256 currentlyWinningBidAmount = auctionIdToWinningBid[auctionId];
    uint256 auctionStartPrice = auctionIdToStartPrice[auctionId];
    uint256 minBidIncrement = auctionIdToMinBidIncrement[auctionId];
    if (currentlyWinningBidAmount > auctionStartPrice) {
      return currentlyWinningBidAmount.add(minBidIncrement);
    } else {
      return auctionStartPrice;
    }
  }

  /**
   * @notice Stores the requisite pricing information for a descending price auction.
     Takes a 2% cut of the startPrice
   */
  function setAuctionPricing(uint256 startPrice, uint256 duration, uint256 minBidIncrement, uint256 auctionId) requiresFee(startPrice.div(50)) internal {
    require(startPrice > 0 && duration > 0 && minBidIncrement > 0);

    /*TODO: These mappings might be a good case for struct packing (auction info), from both a readability/optimization standpoint;
            i.e. CryptoKitty source uses uint128 to rep money. A uint128 could be used to represent something like 10^33 ETH, which seems like more than enough.*/
    auctionIdToStartPrice[auctionId] = startPrice;
    auctionIdToMinBidIncrement[auctionId] = minBidIncrement;
    auctionIdToEndBlock[auctionId] = block.number.add(duration);
  }
}

// File: contracts/AuctionComponents/Whitelistable.sol

contract Whitelistable is Ownable {
  mapping(address => bool) public whitelist;

  event AddToWhitelist(address _address);
  event RemoveFromWhitelist(address _address);

  modifier isWhitelisted(address _addr) {
    require(inWhitelist(_addr));
    _;
  }

  /**
   * @notice Checks the whitelist for a given address.
   *
   * @param _address The address to check against the whitelist.
   * @return The list of whitelisted addresses.
   */
  function inWhitelist(address _address) public view returns (bool) {
    return whitelist[_address];
  }

  /**
   * @notice Adds an address to the whitelist.
   *
   * @param _address The address to whitelist.
   * @return True on success, false on failure.
   */
  function addToWhitelist(address _address) public onlyOwner returns (bool) {
    if (whitelist[_address]) {
      // Already in the mapping
      return false;
    }

    whitelist[_address] = true;
    emit AddToWhitelist(_address);
    return true;
  }

  /**
   * @dev Removes an address from the whitelist.
   *
   * @param _address The addres to remove from the whitelist.
   * @return True on success, false on failure.
   */
  function removeFromWhitelist(address _address) public onlyOwner returns (bool) {
    if (!whitelist[_address]) {
      // Not currently in the mapping
      return false;
    }

    whitelist[_address] = false;
    emit RemoveFromWhitelist(_address);
    return true;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

// File: contracts/AuctionComponents/ERC721Auction.sol

/**
 * @title ERC721Auction
 *
 * @author The AUX Team
 * @notice Contract for an auction of an ERC721 asset.
 */


contract ERC721Auction is AuctionBase, Whitelistable {
  //Reverse mapping to find auctions based on assets, also acts as a source of truth for whether the asset is still in auction or not.
  mapping(address => mapping(uint256 => uint256)) assetContractToAssetIdToAuctionId;

  mapping(uint256 => address) public auctionIdToAssetContract;
  mapping(uint256 => uint256) public auctionIdToAssetId;

  function setAuctionAsset(address assetContract, uint256 assetId, uint256 auctionId) isWhitelisted(assetContract) internal {
    require(auctionId != 0);
    //Make sure there isn't an existing auction for this asset.
    require(assetContractToAssetIdToAuctionId[assetContract][assetId] == 0);

    auctionIdToAssetContract[auctionId] = assetContract;
    auctionIdToAssetId[auctionId] = assetId;

    assetContractToAssetIdToAuctionId[assetContract][assetId] = auctionId;
    escrowAsset(msg.sender, assetContract, assetId);
  }

  function transferWinnings(address recipient, uint256 auctionId) internal {
    require(auctionId != 0);
    //We really only need to check here that the given auctionId is the last auction that owned the asset, and another instance of this auction has not been created for this asset.
    require(auctionHasAsset(auctionId));

    address assetContractAddress = auctionIdToAssetContract[auctionId];
    ERC721Basic assetContract = ERC721Basic(assetContractAddress);
    uint256 assetId = auctionIdToAssetId[auctionId];
    /*NOTE: Error should be thrown by safeTransferFrom if unapproved.
    require(assetContract.getApproved(assetId) == address(this));*/
    assetContractToAssetIdToAuctionId[assetContractAddress][assetId] = 0;
    assetContract.safeTransferFrom(address(this), recipient, assetId);
  }

  /**
   * @dev Transfers cat from an auction seller to the auction contract. This requires the auction to have been approved for taking control of the cat.
   */
  function escrowAsset(address seller, address auctionAssetContract, uint256 assetId) private {
    ERC721Basic assetContract = ERC721Basic(auctionAssetContract);
    /*NOTE: Error should be thrown by transferFrom if unapproved.
    require(assetContract.getApproved(assetId) == address(this));*/
    assetContract.transferFrom(seller, this, assetId);
  }

  function auctionHasAsset(uint256 auctionId) private view returns (bool) {
    address assetContractForAuction = auctionIdToAssetContract[auctionId];
    uint256 assetId = auctionIdToAssetId[auctionId];

    //An auctionId of 0 represents a non-existent auction, which means the asset isn't in any auction managed by this contract.
    uint256 auctionThatCurrentlyOwnsAsset = assetContractToAssetIdToAuctionId[assetContractForAuction][assetId];


    return(auctionThatCurrentlyOwnsAsset == auctionId && auctionThatCurrentlyOwnsAsset != 0);
  }
}

// File: contracts/Auctions/AscendingPriceERC721Auction.sol

/**
 * @title AscendingPriceERC721Auction
 *
 * @author The AUX Team
 * @notice Contract for an ascending price (English) auction of an ERC721 token.
 */


contract AscendingPriceERC721Auction is AscendingPriceAuction, ERC721Auction {
  /**
  * @notice Creates and starts an auction with the given pricing and asset information.
  * @dev Composes the setup for the AscendingPriceAuction, ERC721Auction and AuctionBase.
  */
  function createAuction(
    uint256 startPrice,
    uint256 duration,
    uint256 minBidIncrement,
    address assetAddress,
    uint256 assetId) whenNotPaused public payable returns (uint256)
    {
    uint256 auctionId = createEmptyAuction();
    setAuctionPricing(startPrice, duration, minBidIncrement, auctionId);
    setAuctionAsset(assetAddress, assetId, auctionId);
    return auctionId;
  }
}
