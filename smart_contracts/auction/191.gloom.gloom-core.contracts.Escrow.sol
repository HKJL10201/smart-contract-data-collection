// SPDX-License-Identifier: MIT
pragma solidity 0.5.3;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/upgrades/contracts/Initializable.sol';
import './MikeToken.sol';

/// @title Gloom - contracts to auction off ERC-20 tokens to the highest bidder (in ETH)
/// @title Escrow contract, to be used in conjunction with AuctionFactory and Auction contracts
/// @author Michael S. Mueller
/// @notice This MVP is designed to handle one auction or one auction invite per address
/// @notice This is a demo, do not use on mainnet
/// @dev Escrow inherits Initializable to ensure Escrow is only initialized once

/*
    ===== OVERVIEW =====

    AUCTION PHASES
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

contract Escrow is Initializable {
  // address of auction that deploys this Escrow instance
  address private auction;
  address private seller;
  address private buyer;
  // number of tokens, 18 decimal precision
  uint256 private tokenAmount;
  address private tokenContractAddress;
  uint256 private winningBid;
  uint256 private tokenBalance;
  uint256 private balance;
  // to track if seller has transferred tokens to Escrow
  bool private sellerOk;
  // to track if buyer has paid winning bid to Escrow
  bool private buyerOk;
  // to track whether seller (through Auction contract) has triggered Withdraw phase
  bool private withdrawOk;

  modifier onlySeller {
    require(msg.sender == seller, 'Sender not authorized');
    _;
  }

  modifier onlyBuyer {
    require(msg.sender == buyer, 'Sender not authorized');
    _;
  }

  modifier onlySellerOrBuyer {
    require(msg.sender == seller || msg.sender == buyer, 'Sender not authorized');
    _;
  }

  modifier onlyAuction {
    require(msg.sender == auction, 'Sender not authorized');
    _;
  }

  modifier onlyBuyerSellerAuctionEscrow {
    require(
      msg.sender == buyer || msg.sender == seller || msg.sender == auction || msg.sender == address(this),
      'Sender not authorized'
    );
    _;
  }

  event LogSellerDelivered(address indexed seller, uint256 tokenAmount);
  event LogBuyerPaid(address indexed buyer, uint256 amount);
  event LogSellerWithdrew(address indexed seller, uint256 amount);
  event LogBuyerWithdrew(address indexed buyer, uint256 tokenAmount);

  /// @notice Initialize Escrow in Auction Delivery phase with seller address, ERC-20 token amount and address, and winning bidder and bid
  /// @dev Initializable contracts have initialize function instead of constructor
  /// @dev initializer modifier prevents function from being called twice
  /// @dev Solidity casts winning bid from bytes32 to uint256 here, consider using OpenZeppelin SafeCast.sol
  /// @param _seller address of seller triggering Auction deploy
  /// @param _buyer address of winning bidder
  /// @param _tokenAmount uint number of tokens being auctioned, assumed 18 decimal precision
  /// @param _tokenContractAddress contract address of token being auction, assumed ERC-20
  /// @param _winningBid 32-byte hex encoding of winning bid amount (left zero-padded on front end)
  function initialize(
    address _seller,
    address _buyer,
    uint256 _tokenAmount,
    address _tokenContractAddress,
    bytes32 _winningBid
  ) public initializer {
    auction = msg.sender;
    seller = _seller;
    buyer = _buyer;
    tokenAmount = _tokenAmount;
    tokenContractAddress = _tokenContractAddress;
    winningBid = uint256(_winningBid);
  }

  /// @notice Get token amount being auctioned 
  /// @dev Used in frontend to show token amount to both seller and buyer
  /// @dev Should return same as getter in Auction contract, could refactor to use one getter across both contracts
  /// @return number of tokens being auctioned
  function getTokenAmount() external view onlySellerOrBuyer returns (uint256) {
    return tokenAmount;
  }

  /// @notice Get contract address of token being auctioned 
  /// @dev Used in frontend to show contract token address to both seller and buyer
  /// @dev Should return same as getter in Auction contract, could refactor to use one getter across both contracts
  /// @return contract address of tokens being auctioned
  function getTokenContractAddress() external view onlySellerOrBuyer returns (address) {
    return tokenContractAddress;
  }

  /// @notice Get winning bid
  /// @dev Used in frontend to show winning bid to both seller and buyer
  /// @dev Should return same as getter in Auction contract, could refactor to use one getter across both contracts
  /// @return winning bid (in ETH)
  function getWinningBid() external view onlySellerOrBuyer returns (uint256) {
    return winningBid;
  }

  /// @notice Transfer of seller ERC-20 tokens to escrow contract
  /// @dev Frontend calls approve() of ERC-20 token before transferFrom() may be called
  /// @dev Frontend could have user make transfer() directly, but separation allows for earlier approve(), e.g. in Setup phase, if so desired
  /// @dev Performs state updates before external call to prevent reentrancy attack
  function sellerDelivery() external onlySeller {
    tokenBalance += tokenAmount;
    sellerOk = true;
    require(IERC20(tokenContractAddress).transferFrom(msg.sender, address(this), tokenAmount), 'Transfer failed');
    emit LogSellerDelivered(msg.sender, tokenAmount);
  }

  /// @notice Transfer of buyer's winning bid (in ETH) to escrow contract
  /// @dev Frontend handles buyer transfer
  function buyerPayment() external payable onlyBuyer {
    require(msg.value == winningBid, 'Incorrect amount');
    balance += msg.value;
    buyerOk = true;
    emit LogBuyerPaid(msg.sender, msg.value);
  }

  /// @notice Check if both seller has transferred tokens and buyer has transferred winning bid (in ETH) to Escrow
  /// @return true if both have transferred, false if either one has not
  function bothOk() public view onlyBuyerSellerAuctionEscrow returns (bool) {
    return sellerOk && buyerOk;
  }

  /// @notice Check if seller (through Auction contract) has triggered Withdraw phase
  /// @return true if Withdraw phase has been triggered, false if not
  function startWithdraw() external onlyAuction returns (bool) {
    return withdrawOk = true;
  }

  /// @notice Checks if escrow is complete, if so allows Seller to withdraw winning bid (in ETH)
  /// @dev Performs state updates before external call to prevent reentrancy attack
  function sellerWithdraw() external payable onlySeller {
    require(bothOk(), 'Escrow is not complete');
    require(withdrawOk, 'Action not authorized now');
    require(address(this).balance >= winningBid, 'Insufficient balance');
    balance -= winningBid;
    (bool success, ) = msg.sender.call.value(winningBid)('');
    require(success, 'Transfer failed');
    emit LogSellerWithdrew(msg.sender, winningBid);
  }

  /// @notice Checks if escrow is complete, if so allows Buyer to withdraw tokens
  /// @dev Performs state updates before external call to prevent reentrancy attack
  function buyerWithdraw() external onlyBuyer {
    require(bothOk(), 'Escrow is not complete');
    require(withdrawOk, 'Action not authorized now');
    require(IERC20(tokenContractAddress).balanceOf(address(this)) >= tokenAmount, 'Insufficient balance');
    tokenBalance -= tokenAmount;
    require(IERC20(tokenContractAddress).transfer(msg.sender, tokenAmount), 'Transfer failed');
    emit LogBuyerWithdrew(msg.sender, tokenAmount);
  }
}
