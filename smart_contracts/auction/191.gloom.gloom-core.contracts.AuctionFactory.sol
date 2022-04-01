// SPDX-License-Identifier: MIT
pragma solidity 0.5.3;

import '@openzeppelin/upgrades/contracts/upgradeability/ProxyFactory.sol';
import '@openzeppelin/contracts/lifecycle/Pausable.sol';
import './Auction.sol';

/// @title Gloom - contracts to auction off ERC-20 tokens to the highest bidder (in ETH)
/// @title AuctionFactory contract, to be used in conjunction with Auction and Escrow contracts
/// @author Michael S. Mueller
/// @notice This MVP is designed to handle one auction or one auction invite per address
/// @notice This is a demo, do not use on mainnet
/// @dev AuctionFactory inherits ProxyFactory to allow minimal proxy deploy of Auction instances
/// @dev AuctionFactory inherits Pausable to allow admin to pause deploy of new Auction instances

/*
    ===== OVERVIEW =====
    
    PHASES
    - Phase begins in Setup, later Seller triggers move to Commit, Reveal, Deliver, Withdraw

    SETUP
    - Seller configures (but does not transfer) ERC-20 token amount and address
    - Auction Factory deploys new clone of Auction (logic) contract with this configuration
    - Seller makes seller deposit (in ETH) into Auction
    - Seller specifies bidder deposit requirement (in ETH) and invites bidders to Auction

    COMMIT
    - Bidders deposit into Auction (in ETH) and commit a hash (with salt) of their bid (denominated in ETH)
 
    REVEAL
    - Bidders reveal their bids, Auction contract assigns winner and deploys new Escrow contract

    DELIVER
    - Seller transfers (using approve / transferFrom pattern) their ERC-20 tokens into Escrow
    - Winning bidder transfers winning bid (in ETH) to Escrow

    WITHDRAW
    - Seller withdraws their seller deposit (in ETH) from Auction and the winning bid proceeds (in ETH) from Escrow
    - Bidder withdraws their bidder deposit (in ETH) from Auction and ERC-20 tokens from Escrow
*/

contract AuctionFactory is ProxyFactory, Pausable {

  address public admin;
  address[] private auctionAddresses;
  mapping(address => bool) private auctionExists;

  // seller's auction
  mapping(address => address) private auctionBy;

  // auction to which bidder has been invited
  mapping(address => address) private auctionInvited;

  event LogAuctionCreated(address indexed auction, address indexed seller);
  event LogBidderRegistered(address indexed auction, address indexed bidder);

  constructor() public Pausable() {
    admin = msg.sender;
  }

  modifier onlyAdmin {
    require(msg.sender == admin, 'Sender not authorized');
    _;
  }

  /// @notice Pauses ability to deploy new auctions, does not affect existing auctions
  function pauseFactory() external onlyAdmin {
    pause();
  }

  /// @notice Resumes ability to deploy new auctions
  function unpauseFactory() external onlyAdmin {
    unpause();
  }

  /// @notice Get deployed auctions
  /// @dev Used in testing but not in frontend
  /// @return Array of addresses of deployed auctions
  function getAddresses() external view onlyAdmin returns (address[] memory) {
    return auctionAddresses;
  }

  /// @notice Get auction deployed by a seller
  /// @dev Used in frontend to allow user to interact with their auction
  /// @return Auction address which sender has deployed
  function getAuctionBy() external view returns (address) {
    return auctionBy[msg.sender];
  }

  /// @notice Get auction to which a bidder has been invited
  /// @dev Used in frontend to allow user to interact with auction they have been invited to
  /// @return Auction address which sender has been invited to
  function getAuctionInvited() external view returns (address) {
    return auctionInvited[msg.sender];
  }

  /// @notice Deploys new auction
  /// @dev Uses minimal proxy deployMinimal function
  /// @dev tokenContractAddress should be contract address of deployed ERC-20 token for network
  /// @param logic address of pre-deployed Auction contract to be cloned
  /// @param tokenAmount uint number of tokens being auctioned, assumed 18 decimal precision
  /// @param tokenContractAddress contract address of token being auction, assumed ERC-20
  function createAuction(
    address logic,
    uint256 tokenAmount,
    address tokenContractAddress
  ) external whenNotPaused() {
    address seller = msg.sender;
    bytes memory payload =
      abi.encodeWithSignature('initialize(address,uint256,address)', seller, tokenAmount, tokenContractAddress);
    address auction = deployMinimal(logic, payload);
    auctionAddresses.push(auction);
    auctionExists[auction] = true;
    auctionBy[seller] = auction;
    emit LogAuctionCreated(auction, seller);
  }

  /// @notice Registers bidder that has been invited to an Auction
  /// @dev Only may be called by existing deployed Auction
  /// @param bidder address of bidder being registered
  function registerBidder(address bidder) external {
    require(auctionExists[msg.sender], 'Sender not authorized');
    auctionInvited[bidder] = msg.sender;
    emit LogBidderRegistered(msg.sender, bidder);
  }
}
