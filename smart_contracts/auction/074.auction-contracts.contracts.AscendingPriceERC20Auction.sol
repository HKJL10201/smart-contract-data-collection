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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/AuctionComponents/ERC20Auction.sol

/**
 * @title ERC20Auction
 *
 * @author The AUX Team
 * @notice Contract for an auction for a lot of ERC20 tokens - one bidder take all.
 */


contract ERC20Auction is AuctionBase, Whitelistable {
  mapping(uint256 => address) public auctionIdToERC20Address;
  mapping(uint256 => uint256) public auctionIdToAmount;

  /**
  * @notice Stores the given information for an auction for the given tokens, then attempts to transfer the tokens from the auction seller to this contract to start the auction.
  */
  function setAuctionAsset(address tokenAddress, uint256 tokenAmount, uint256 auctionId) isWhitelisted(tokenAddress) internal {
    //NOTE: auctionId check requirement might not be necessary.
    require(tokenAmount > 0 && auctionId != 0);
    auctionIdToERC20Address[auctionId] = tokenAddress;
    auctionIdToAmount[auctionId] = tokenAmount;
    escrowERC20Tokens(msg.sender, tokenAddress, tokenAmount);
  }

  function transferWinnings(address recipient, uint256 auctionId) internal {
    require(auctionId != 0);
    require(auctionHasAssets(auctionId));
    ERC20 erc20Contract = ERC20(auctionIdToERC20Address[auctionId]);
    /*NOTE: Error should be thrown by transfer if unapproved, this require is unnecessary gas.
    require(token.getApproved(kittyId) == address(this));*/
    uint256 tokenAmount = auctionIdToAmount[auctionId];
    auctionIdToAmount[auctionId] = 0;
    erc20Contract.transfer(recipient, tokenAmount);
  }

  /**
   * @dev Transfers tokens from an auction seller to the auction contract. This requires the auction to have been approved for taking control of the ERC20 tokens.
   */
  function escrowERC20Tokens(address auctionSeller, address tokenAddress, uint256 tokenAmount) private {
    ERC20 erc20Contract = ERC20(tokenAddress);
    /*NOTE: Error should be thrown by transferFrom if unapproved, this require is unnecessary gas.
    require(token.getApproved(kittyId) == address(this));*/
    erc20Contract.transferFrom(auctionSeller, this, tokenAmount);
  }

  function auctionHasAssets(uint256 auctionId) private view returns (bool) {
    return (auctionIdToAmount[auctionId] != 0);
  }
}

// File: contracts/Auctions/AscendingPriceERC20Auction.sol

/**
 * @title AscendingPriceERC20Auction
 *
 * @author The AUX Team
 * @notice Contract for an ascending price (English) auction of an ERC20 token.
 */


contract AscendingPriceERC20Auction is AscendingPriceAuction, ERC20Auction {

  /*TODO: Account for entry via ERC223 payment fallback function with data (ERC827 should work out of the box)

  We should implement:
    function tokenFallback(address _from, uint _value, bytes _data) { ... }

  So that our Web3 interface can create an auction with one Web3 step by calling:
    function transfer(address _to, uint _value, bytes _data) returns (bool)
  */

  /**
  * @notice Creates and starts an auction with the given pricing and asset information.
  * @dev Composes the setup for the AscendingPriceAuction, ERC20Auction and AuctionBase.
  */
  function createAuction(
    uint256 startPrice,
    uint256 duration,
    uint256 minBidIncrement,
    address tokenAddress,
    uint256 tokenAmount) whenNotPaused public payable
    {
    uint256 auctionId = createEmptyAuction();
    setAuctionPricing(startPrice, duration, minBidIncrement, auctionId);
    setAuctionAsset(tokenAddress, tokenAmount, auctionId);
  }
}
