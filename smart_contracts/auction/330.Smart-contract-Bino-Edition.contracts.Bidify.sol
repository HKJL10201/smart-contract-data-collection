// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Bidify is ReentrancyGuard, Ownable, IERC165, ERC1155Holder {
  using SafeERC20 for IERC20;
  // All prices will now be 0.0001, 0.0002, 0.0010...
  // For coins with less accuracy, such as USD stablecoins, it'll be 0.01, 0.02...
  uint8 constant DECIMAL_ACCURACY = 4;

  // Time to extend the auction by if a last minute bid appears
  uint256 constant EXTENSION_TIMER = 3 minutes;

  address constant BIDIFY_ETH = 0x3Ddf0eB83c26043fE5464E06D9E338D289cFFBc1;
  // Lack of payable on addresses due to usage of call
  struct Listing {
    address creator;
    address currency;
    address platform;
    uint256 token;
    uint256 price;
    uint256 endingPrice;
    address referrer;
    address lister;
    address highBidder;
    uint256 endTime;
    bool paidOut;
    bool isERC721;
  }

  mapping(uint256 => Listing) private _listings;
  uint64 private _nextListing;
  uint256 _lastReceived;

  event ListingCreated(uint64 indexed id, address indexed creator, address currency, address indexed platform, uint256 token, uint256 price, uint256 endingPrice, uint8 timeInDays, address lister);
  event Bid(uint64 indexed id, address indexed bidder, uint256 price, address referrer);
  event AuctionExtended(uint64 indexed id, uint256 time);
  event AuctionFinished(uint64 indexed id, address indexed nftRecipient, uint256 price);

  // Fallbacks to return ETH flippantly sent
  receive() payable external {
    require(false);
  }
  fallback() payable external {
    require(false);
  }

  constructor() Ownable() {}

  function onERC721Received(address operator, address, uint256 tokenId, bytes calldata) external returns (bytes4) {
    require(operator == address(this), "someone else sent us an NFT");
    _lastReceived = tokenId;
    return IERC721Receiver.onERC721Received.selector;
  }
  function onERC1155Received(address operator, address, uint256 tokenId, bytes calldata) external returns (bytes4) {
    require(operator == address(this), "someone else sent us an NFT");
    _lastReceived = tokenId;
    return IERC1155Receiver.onERC1155Received.selector;
  }
  // Get the minimum accuracy unit for a given accuracy
  function getPriceUnit(address currency) public view returns (uint256) {
    if (currency == address(0)) {
      return 10 ** (18 - DECIMAL_ACCURACY);
    }

    // This technically doesn't work with all ERC20s
    // The decimals method is optional, hence the custom interface
    // That said, it is in almost every ERC20, a requirement for this, and needed for feasible operations with wrapped coins
    uint256 decimals = ERC20(currency).decimals();

    if (decimals <= DECIMAL_ACCURACY) {
      return 1;
    }
    return 10 ** (decimals - DECIMAL_ACCURACY);
  }

  // Only safe to call once per function due to how ETH is handled
  // transferFrom(5) + transferFrom(5) is just 5 on ETH; not 10
  function universalSingularTransferFrom(address currency, uint256 amount) internal {
    if (currency == address(0)) {
      require(msg.value == amount, "invalid ETH value");
    } else {
      IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);
    }
  }

  function universalTransfer(address currency, address dest, uint256 amount) internal {
    if (currency == address(0)) {
      // _balances[dest] = _balances[dest] + amount;
      (bool success,) = dest.call{value: amount}("");
      require(success);
    } else {
      IERC20(currency).safeTransfer(dest, amount);
    }
  }

  function getListing(uint256 id) external view returns (Listing memory) {
    return _listings[id];
  }
  
  function list(address currency, address platform, uint256 token, uint256 price, uint256 endingPrice, uint8 timeInDays, bool isERC721, address lister) external nonReentrant returns (uint256) {
    
    uint256 unit = getPriceUnit(currency);
    // Ensure it's a multiple of the price unit
    require(((price / unit) * unit) == price, "price isn't a valid multiple of this currency's price unit");
    require(timeInDays <= 30, "auction is too long");

    uint64 id = _nextListing;
    _nextListing = _nextListing + 1;

    // Re-entrancy opportunity
    // Given the usage of _lastReceived when we create the listing object, this does need the guard
    if(isERC721)
    {
      IERC721(platform).safeTransferFrom(msg.sender, address(this), token);
      _listings[id] = Listing(
        msg.sender,
        currency,
        platform,
        token,
        price,
        endingPrice,
        address(0),
        lister,
        address(0),
        block.timestamp + (timeInDays * (1 days)),
        false,
        true
      );
    }
    else {
      IERC1155(platform).safeTransferFrom(msg.sender, address(this), token, 1, "");
      _listings[id] = Listing(
        msg.sender,
        currency,
        platform,
        token,
        price,
        endingPrice,
        address(0),
        lister,
        address(0),
        block.timestamp + (timeInDays * (1 days)),
        false,
        false
      );
    }
    emit ListingCreated(id, msg.sender, currency, platform, token, price, endingPrice, timeInDays, lister);

    return id;
  }

  function getNextBid(uint64 id) public view returns (uint256) {
    // Increment by 5% at a time, rounding to the price unit
    // This has two effects; stopping micro-bids, which isn't too relevant due to Eth gas fees
    // It also damages marking up. If a NFT is at 1 ETH, this prevents doing 1.0001 ETH to immediately resell
    // This requires doing at least 1.05 ETH, a much more noticeable amount
    // This would risk flatlining (1 -> 1 -> 1) except there is a minimal list price of 20 units
    Listing memory listing = _listings[id];
    if (listing.highBidder == address(0)) {
      return listing.price;
    }
    return listing.price + listing.price / 20;
  }

  function bid(uint64 id, address referrer, uint256 amount) external payable nonReentrant {
    // Make sure the auction exists
    // Only works because list and bid have a shared reentrancy guard
    require(id < _nextListing, "listing doesn't exist");
    Listing storage listing = _listings[id];

    require(listing.highBidder != msg.sender, "already the high bidder");
    require(block.timestamp < listing.endTime, "listing ended");
    // if (!listing.allowMarketplace) {
      // require(marketplace == address(0), "marketplaces aren't allowed on this auction");
    // }

    uint256 nextBid = getNextBid(id);
    require(nextBid <= amount, "Bid amount should not be less than Next bid amount");
    // This loses control of execution, yet no variables are set yet
    // This means no interim state will be represented if asked
    // Combined with the re-entrancy guard, this is secure
    universalSingularTransferFrom(listing.currency, amount);

    // We could grab price below, and then set, yet the lost contract execution is risky
    // Despite the lack of re-entrancy, the metadata would be wrong, if asked for
    uint256 oldPrice = listing.price;
    address oldBidder = listing.highBidder;

    // Note the new highest bidder
    listing.price = amount;
    listing.highBidder = msg.sender;
    listing.referrer = referrer;
    emit Bid(id, msg.sender, listing.price, referrer);

    // Prevent sniping via extending the bid timer, if this was last-minute
    if ((block.timestamp + EXTENSION_TIMER) > listing.endTime) {
      listing.endTime = block.timestamp + EXTENSION_TIMER;
      emit AuctionExtended(id, listing.endTime);
    }

    // Pay back the old bidder who is now out of the game
    // Okay to lose execution as this is the end of the function
    if (oldBidder != address(0)) {
      universalTransfer(listing.currency, oldBidder, oldPrice);
    }

    // Finish bidding immediately if a bid is made which matches or exceeds the specified Buy it now price
    if (listing.price >= listing.endingPrice && listing.endingPrice != 0) {
      listing.endTime = block.timestamp - 1;
      _finish(id);
    }
  }
  function _finish(uint64 id) internal {
    require(id < _nextListing, "listing doesn't exist");

    Listing storage listing = _listings[id];
    require(listing.endTime < block.timestamp, "listing has yet to end");

    // These two lines make re-entrancy a non-issue
    // That said, this is critical to no be re-entrant, hence why the guard remains
    // It should only removed to save a microscopic amount of gas
    // Speaking of re-entrancy, any external contract which gains control will mis-interpret the metadata
    // Since we do multiple partial payouts, we can either claim not paid out or paid out and be incorrect either way
    // Or we can add a third state "paying out" for an extremely niche mid-payout re-entrant (on the contract level) case
    // This just claims paid out and moves on
    require(!listing.paidOut, "listing was already paid out");
    listing.paidOut = true;

    // The NFT goes to someone, yet if it's the creator/highBidder is undetermined
    address nftRecipient;
    // Set to 0 if there were no bidders
    uint256 sellPrice = listing.price;
    // If there was a bidder...
    if (listing.highBidder != address(0)) {
      // 4% fee
      uint256 originalFees = listing.price / 25;
      uint256 ownerFees = originalFees;
      uint256 referFees = originalFees / 4;

      if (listing.referrer != address(0)) {
        universalTransfer(listing.currency, listing.referrer, referFees);
        ownerFees -= referFees;
      }

      if(listing.lister != address(0)) {
        universalTransfer(listing.currency, listing.lister, referFees);
        ownerFees -= referFees;
      }

      // Rest of the fees goes to the platform's creators
      universalTransfer(listing.currency, BIDIFY_ETH, ownerFees);

      // Pay out the listing (post fees)
      universalTransfer(listing.currency, listing.creator, listing.price - originalFees);

      // Note the NFT recipient
      nftRecipient = listing.highBidder;
    // Else, restore ownership to the owner
    } else {
      nftRecipient = listing.creator;
      sellPrice = 0;
    }
    if(listing.isERC721)
      IERC721(listing.platform).safeTransferFrom(address(this), nftRecipient, listing.token);
    else
      IERC1155(listing.platform).safeTransferFrom(address(this), nftRecipient, listing.token, 1, "");
    emit AuctionFinished(id, nftRecipient, sellPrice);
  }
  function finish(uint64 id) external nonReentrant {
    _finish(id);
  }
}
