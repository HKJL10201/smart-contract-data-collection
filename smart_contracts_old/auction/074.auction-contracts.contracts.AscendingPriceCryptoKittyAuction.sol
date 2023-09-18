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

// File: contracts/CryptoKitty/CKERC721.sol

/* solium-disable */

//NOTE: Intentional, older version of Solidity to keep in line with deployed CK contracts.
pragma solidity ^0.4.11;

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract CKERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

// File: contracts/AuctionComponents/CryptoKittyAuction.sol

/**
 * @title CryptoKittyAuction
 *
 * @author The AUX Team
 * @notice Contract for an auction of a CryptoKitty.
 */


contract CryptoKittyAuction is AuctionBase {
  using SafeMath for uint256;

  //Reverse mapping to find auctions based on cats, also acts as a source of truth for whether the cat is still in auction or not.
  mapping(uint256 => uint256) public kittyIdToAuctionId;

  mapping(uint256 => uint256) public auctionIdToKittyId;

  address public cryptoKittyAddress;

  constructor(address _cryptoKittyAddress) public {
    cryptoKittyAddress = _cryptoKittyAddress;
  }

  function setAuctionAsset(uint256 kittyId, uint256 auctionId) internal {
    require(auctionId != 0);
    //Make sure there isn't an existing auction for this asset.
    require(kittyIdToAuctionId[kittyId] == 0);

    auctionIdToKittyId[auctionId] = kittyId;

    kittyIdToAuctionId[kittyId] = auctionId;

    escrowKitty(msg.sender, kittyId);
  }

  function transferWinnings(address recipient, uint256 auctionId) internal {
    require(auctionId != 0);
    require(auctionHasKitty(auctionId));
    CKERC721 catContract = CKERC721(cryptoKittyAddress);
    /*NOTE: Error should be thrown by transfer if unapproved, this require is unnecessary gas.
    require(token.getApproved(kittyId) == address(this));*/
    uint256 kittyId = auctionIdToKittyId[auctionId];
    kittyIdToAuctionId[kittyId] = 0;
    catContract.transfer(recipient, kittyId);
  }

  /**
   * @dev Transfers cat from an auction seller to the auction contract. This requires the auction to have been approved for taking control of the cat.
   */
  function escrowKitty(address seller, uint256 kittyId) private {
    CKERC721 catContract = CKERC721(cryptoKittyAddress);
    /*NOTE: Error should be thrown by transferFrom if unapproved.
    require(token.getApproved(kittyId) == address(this));*/
    catContract.transferFrom(seller, this, kittyId);
  }

  function auctionHasKitty(uint256 auctionId) private view returns (bool) {
    uint256 kittyId = auctionIdToKittyId[auctionId];

    //An auctionId of 0 represents a non-existent auction, which means the kitty isn't in any auction managed by this contract.
    uint256 auctionThatCurrentlyOwnsKitty = kittyIdToAuctionId[kittyId];

    return(auctionThatCurrentlyOwnsKitty == auctionId);
  }
}

// File: contracts/Auctions/AscendingPriceCryptoKittyAuction.sol

/**
 * @title AscendingPriceCryptoKittyAuction
 *
 * @author The AUX Team
 * @notice Contract for an "Ascending Price" (English) auction of a CryptoKitty token.
 */


contract AscendingPriceCryptoKittyAuction is AscendingPriceAuction, CryptoKittyAuction {
  constructor(address _cryptoKittyAddress) CryptoKittyAuction(_cryptoKittyAddress) public { }

  /**
  * @notice Creates and starts an auction with the given pricing and asset information.
  * @dev Composes the setup for the AscendingPriceAuction, CryptoKittyAuction and AuctionBase.
  */
  function createAuction(uint256 startPrice, uint256 duration, uint256 minBidIncrement, uint256 kittyId) whenNotPaused public payable returns (uint256) {
    uint256 auctionId = createEmptyAuction();
    setAuctionPricing(startPrice, duration, minBidIncrement, auctionId);
    setAuctionAsset(kittyId, auctionId);
    return auctionId;
  }
}
