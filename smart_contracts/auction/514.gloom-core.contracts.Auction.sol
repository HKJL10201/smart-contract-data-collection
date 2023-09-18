// SPDX-License-Identifier: MIT
pragma solidity 0.5.3;

import '@openzeppelin/upgrades/contracts/Initializable.sol';
import './AuctionFactory.sol';
import './Escrow.sol';

/// @title Gloom - contracts to auction off ERC-20 tokens to the highest bidder (in ETH)
/// @title Auction contract, to be used in conjunction with AuctionFactory and Escrow contracts
/// @author Michael S. Mueller
/// @notice This MVP is designed to handle one auction or one auction invite per address
/// @notice This is a demo, do not use on mainnet
/// @dev Auction inherits Initializable to ensure Auction is only initialized once

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

contract Auction is Initializable {
  address private factory;
  address payable private seller;
  address private winner;
  uint256 private sellerDeposit;
  uint256 private bidderDeposit;
  // number of tokens, 18 decimal precision
  uint256 private tokenAmount;
  address private tokenContractAddress;
  mapping(address => uint256) private balances;
  Escrow private escrow;

  // seller controls movement from one phase to the next
  enum Phase { Setup, Commit, Reveal, Deliver, Withdraw }
  Phase private phase;

  // bidCommit is hashed and salted bid (hidden from other bidders)
  // bidHex is bid once it has been revealed
  struct Bidder {
    bool isInvited;
    bytes32 bidCommit;
    uint64 bidCommitBlock;
    bool isBidRevealed;
    bytes32 bidHex;
  }
  mapping(address => Bidder) private bidders;
  address[] private bidderAddresses;

  event LogSellerDepositReceived(address indexed seller, uint256 sellerDeposit);
  event LogSellerDepositWithdrawn(address indexed seller, uint256 amount);
  event LogBidderDepositReceived(address indexed bidder, uint256 bidderDeposit);
  event LogBidderDepositWithdrawn(address indexed bidder, uint256 amount);
  event LogBidderInvited(address indexed bidder);
  event LogBidCommitted(address indexed bidder, bytes32 bidHash, uint256 bidCommitBlock);
  event LogBidRevealed(address indexed bidder, bytes32 bidHex, bytes32 salt);

  event LogSetWinner(address indexed bidder, uint256 bid);
  event LogPhaseChangeTo(string phase);

  modifier onlySeller {
    require(msg.sender == seller, 'Sender not authorized');
    _;
  }

  modifier onlyBidder {
    require(isInvitedBidder(msg.sender), 'Sender not authorized');
    _;
  }

  modifier onlySellerOrBidder {
    require(msg.sender == seller || isInvitedBidder(msg.sender), 'Sender not authorized');
    _;
  }

  modifier onlySellerOrWinner {
    require(msg.sender == seller || msg.sender == winner, 'Sender not authorized');
    _;
  }

  modifier inSetup {
    require(phase == Phase.Setup, 'Action not authorized now');
    _;
  }

  modifier inCommit {
    require(phase == Phase.Commit, 'Action not authorized now');
    _;
  }

  modifier inReveal {
    require(phase == Phase.Reveal, 'Action not authorized now');
    _;
  }

  modifier inDeliver {
    require(phase == Phase.Deliver, 'Action not authorized now');
    _;
  }

  modifier inWithdraw {
    require(phase == Phase.Withdraw, 'Action not authorized now');
    _;
  }

  /// @notice Initialize Auction in Setup phase with seller address and ERC-20 token amount and address
  /// @dev Initializable contracts have initialize function instead of constructor
  /// @dev initializer modifier prevents function from being called twice
  /// @param _seller address of seller triggering Auction deploy
  /// @param _tokenAmount uint number of tokens being auctioned, assumed 18 decimal precision
  /// @param _tokenContractAddress contract address of token being auction, assumed ERC-20
  function initialize(
    address payable _seller,
    uint256 _tokenAmount,
    address _tokenContractAddress
  ) public initializer {
    factory = msg.sender;
    seller = _seller;
    tokenAmount = _tokenAmount;
    tokenContractAddress = _tokenContractAddress;
    phase = Phase.Setup;
  }

  // PHASE CONTROL ONLY SELLER

  /// @notice Start commit
  /// @dev Frontend listens for phase change logs to update UI
  function startCommit() external onlySeller inSetup {
    phase = Phase.Commit;
    emit LogPhaseChangeTo('Commit');
  }

  /// @notice Start commit
  function startReveal() external onlySeller inCommit {
    phase = Phase.Reveal;
    emit LogPhaseChangeTo('Reveal');
  }

  /// @notice Start delivery, determine winner, deploy new escrow contract
  function startDeliver() external onlySeller inReveal {
    phase = Phase.Deliver;
    setWinner();
    deployEscrow();
    emit LogPhaseChangeTo('Deliver');
  }

  /// @notice Check that seller has transferred tokens and buyer has paid, then start withdraw
  /// @dev Could update to use minimal proxy pattern to deploy escrow with less gas
  function startWithdraw() external onlySeller inDeliver {
    require(escrow.bothOk(), 'Escrow incomplete');
    require(escrow.startWithdraw(), 'Error starting escrow withdraw');
    phase = Phase.Withdraw;
    emit LogPhaseChangeTo('Withdraw');
  }

  // ALL PHASES PUBLIC

  /// @notice Get salt and hash of bid
  /// @dev Used in frontend in Commit phase and internally in Reveal phase
  /// @return bytes32 keccak hash of salted bid
  /// @param data 32-byte hex encoding of bid amount (left zero-padded on front end)
  /// @param salt 32-byte hex encoding of bidder password (from front end)
  function getSaltedHash(bytes32 data, bytes32 salt) public view returns (bytes32) {
    return keccak256(abi.encodePacked(address(this), data, salt));
  }

  // ALL PHASES PRIVATE

  /// @notice Check if a bidder is invited to Auction
  /// @dev Used in onlySellerOrBidder modifier and in require statements as check
  /// @return true if invited, false if not
  /// @param bidderAddress bidder address to check
  function isInvitedBidder(address bidderAddress) private view returns (bool) {
    return bidders[bidderAddress].isInvited;
  }

  // ALL PHASES ONLY SELLER

  /// @notice Get bidders to Auction
  /// @dev Used in frontend to show bidders to seller
  /// @return array of bidder addresses
  function getBidders() external view onlySeller returns (address[] memory) {
    return bidderAddresses;
  }

  // ALL PHASES ONLY SELLER OR BIDDER

  /// @notice Get current Auction phase
  /// @dev Used in frontend to show phase to both seller and bidders
  /// @return string representation of current phase
  function getPhase() external view onlySellerOrBidder returns (string memory) {
    if (phase == Phase.Setup) return 'Setup';
    if (phase == Phase.Commit) return 'Commit';
    if (phase == Phase.Reveal) return 'Reveal';
    if (phase == Phase.Deliver) return 'Deliver';
    if (phase == Phase.Withdraw) return 'Withdraw';
  }

  /// @notice Get details of token being auctioned at any time
  /// @dev Used in frontend to show asset details to both seller and bidders
  /// @return number and contract address of tokens being auctioned
  function getAsset() external view onlySellerOrBidder returns (uint256, address) {
    return (tokenAmount, tokenContractAddress);
  }

  /// @notice Get seller deposit amount at any time
  /// @dev Used in frontend to show seller deposit amount to both seller and bidders
  /// @return amount of ETH seller has deposited
  function getSellerDeposit() external view onlySellerOrBidder returns (uint256) {
    return sellerDeposit;
  }

  /// @notice Get bidder deposit requirement amount at any time
  /// @dev Used in frontend to show bidder deposit requirement to both seller and bidders
  /// @return amount of ETH bidders are required to deposit in order to commit bid
  function getBidderDeposit() external view onlySellerOrBidder returns (uint256) {
    return bidderDeposit;
  }

  /// @notice Get winning bidder address and bid at any time, will have results from Deliver phase
  /// @dev Used in frontend to show winning bidder and bid to both seller and bidders
  /// @return winner address and bid (in ETH)
  function getWinner() external view onlySellerOrBidder returns (address, uint256) {
    uint256 winningBid = uint256(bidders[winner].bidHex);
    return (winner, winningBid);
  }

  // ALL PHASES ONLY SELLER OR WINNER

  /// @notice Get address of deployed Escrow contract at any time
  /// @dev Used in frontend to obtain escrow contract address for seller and winner
  /// @return address of deployed Escrow contract
  function getEscrow() external view onlySellerOrWinner returns (Escrow) {
    return escrow;
  }

  // SETUP PHASE ONLY SELLER

  /// @notice Receives seller deposit (in ETH) in Setup phase
  /// @dev Frontend handles seller transfer
  /// @dev Seller can submit (and change) sellerDeposit multiple times, which should be controlled for (e.g. multiple deposits)
  function receiveSellerDeposit() external payable onlySeller inSetup {
    sellerDeposit = msg.value;
    balances[msg.sender] += msg.value;
    emit LogSellerDepositReceived(msg.sender, msg.value);
  }

  /// @notice Registers bidder at Auction Factory in Setup phase
  /// @dev We need Auction Factory to know who the bidders are to identify them in front end
  /// @param bidderAddress bidder address to register at Auction Factory
  function registerBidderAtFactory(address bidderAddress) private {
    AuctionFactory auctionFactory = AuctionFactory(factory);
    auctionFactory.registerBidder(bidderAddress);
  }

  /// @notice Invites individual bidder in Setup phase
  /// @param bidderAddress bidder address to invite
  function inviteBidder(address bidderAddress) private {
    require(!isInvitedBidder(bidderAddress), 'Bidder already invited');
    bidders[bidderAddress].isInvited = true;
    bidderAddresses.push(bidderAddress);
    registerBidderAtFactory(bidderAddress);
    emit LogBidderInvited(bidderAddress);
  }

  /// @notice Seller establishes bidder deposit requirement and invite bidders in Setup phase
  /// @dev Seller can call this multiple times, should establish logic to prevent or to handle editing bidder setup
  /// @param _bidderDeposit bidder deposit requirement amount (seller configures on front end when inviting bidders)
  /// @param _bidderAddresses array of bidders to invite (seller configures on front end)
  function setupBidders(uint256 _bidderDeposit, address[] calldata _bidderAddresses) external onlySeller inSetup {
    bidderDeposit = _bidderDeposit;
    for (uint256 i = 0; i < _bidderAddresses.length; i++) {
      inviteBidder(_bidderAddresses[i]);
    }
  }

  // COMMIT PHASE ONLY BIDDER

  /// @notice Receives bidder deposit (in ETH) in Commit phase
  /// @dev Frontend handles bidder transfer
  function receiveBidderDeposit() private {
    require(msg.value == bidderDeposit, 'Deposit is not required amount');
    balances[msg.sender] += msg.value;
    emit LogBidderDepositReceived(msg.sender, msg.value);
  }

  /// @notice Commit obfuscated bid in Commit phase
  /// @dev Block.number is not currently used but could compare to block.number at reveal to ensure minimal block difference
  /// @param dataHash 32-byte keccak256 hash of bid commit amount and salt (return value of getSaltedHash above called from front end)
  function commitBid(bytes32 dataHash) private {
    bidders[msg.sender].bidCommit = dataHash;
    bidders[msg.sender].bidCommitBlock = uint64(block.number);
    bidders[msg.sender].isBidRevealed = false;
    emit LogBidCommitted(msg.sender, bidders[msg.sender].bidCommit, bidders[msg.sender].bidCommitBlock);
  }

  /// @notice Triggers bidder deposit (in ETH) and commits obfuscated bid in Commit phase
  /// @dev Bidder can submit (and change) bid multiple times, which should be controlled for (e.g. multiple deposits)
  /// @param dataHash 32-byte keccak256 hash of bid commit amount and salt (return value of getSaltedHash above called from front end)
  function submitBid(bytes32 dataHash) external payable onlyBidder inCommit {
    receiveBidderDeposit();
    commitBid(dataHash);
  }

  // REVEAL PHASE ONLY BIDDER

  /// @notice Checks revealed bid in Reveal phase to ensure it matches commit, if so stores revealed bid
  /// @param bidHex 32-byte hex encoding of bid amount (left zero-padded on front end)
  /// @param salt 32-byte hex encoding of bidder password (from front end)
  function revealBid(bytes32 bidHex, bytes32 salt) external onlyBidder inReveal {
    require(bidders[msg.sender].isBidRevealed == false, 'Bid already revealed');
    require(getSaltedHash(bidHex, salt) == bidders[msg.sender].bidCommit, 'Revealed hash does not match');
    bidders[msg.sender].isBidRevealed = true;
    bidders[msg.sender].bidHex = bidHex;
    emit LogBidRevealed(msg.sender, bidHex, salt);
  }

  // DELIVER PHASE INTERNAL TRIGGERED BY PHASE CONTROL ONLY SELLER

  /// @notice Cycles through bids and determines winner at start of Deliver phase
  /// @dev Solidity casts bid from bytes32 to uint256 here, consider using OpenZeppelin SafeCast.sol
  function setWinner() internal {
    address _winner = bidderAddresses[0];
    for (uint256 i = 1; i < bidderAddresses.length; i++) {
      address current = bidderAddresses[i];
      if (bidders[current].bidHex > bidders[_winner].bidHex) {
        _winner = current;
      }
    }
    winner = _winner;
    uint256 winningBid = uint256(bidders[winner].bidHex);
    emit LogSetWinner(winner, winningBid);
  }

  /// @notice Deploys new escrow contract at start of Deliver phase
  /// @dev Could update to use minimal proxy pattern to deploy Escrow with less gas
  function deployEscrow() internal {
    escrow = new Escrow();
    bytes32 winningBid = bidders[winner].bidHex;
    escrow.initialize(seller, winner, tokenAmount, tokenContractAddress, winningBid);
  }

  // WITHDRAW PHASE ONLY SELLER OR BIDDER

  /// @notice Seller withdraws deposit (in ETH) in withdraw phase
  /// @dev Performs state updates before external call to prevent reentrancy attack
  /// @dev To test / control for: effects of multiple and changing seller deposits
  function withdrawSellerDeposit() external payable onlySeller inWithdraw {
    require(balances[msg.sender] >= sellerDeposit, 'Insufficient balance');
    balances[msg.sender] -= sellerDeposit;
    (bool success, ) = msg.sender.call.value(sellerDeposit)('');
    require(success, 'Transfer failed');
    emit LogSellerDepositWithdrawn(msg.sender, sellerDeposit);
  }

  /// @notice Bidder withdraws deposit (in ETH) in withdraw phase
  /// @dev Performs state updates before external call to prevent reentrancy attack
  /// @dev To test / control for: effects of multiple and changing deposits by same bidder
  function withdrawBidderDeposit() external payable onlyBidder inWithdraw {
    require(balances[msg.sender] >= bidderDeposit, 'Insufficient balance');
    balances[msg.sender] -= bidderDeposit;
    (bool success, ) = msg.sender.call.value(bidderDeposit)('');
    require(success, 'Transfer failed');
    emit LogBidderDepositWithdrawn(msg.sender, bidderDeposit);
  }
}
