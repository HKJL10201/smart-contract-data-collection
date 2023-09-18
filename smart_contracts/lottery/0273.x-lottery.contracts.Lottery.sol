// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/AutomationCompatible.sol';

/* Custom Errors */
error Lottery__NotEnoughETHEntered();
error Lottery__TransfertFailed();
error Lottery__NotOpen();
error Lottery__UpkeepNotNeeded(
  uint256 currentBalance,
  uint256 numPlayers,
  uint256 raffleState
);

/**
 * @title Lottery Smart Contract
 * @author Written by Alex Boisseau and Theo Delas, following the course of Patrick Collins.
 * @dev This contract implement ChainLink VRF v2 and ChainLink Automation.
 */
contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
  /* Type Declarations */
  enum LotteryState {
    OPEN,
    CALCULATING
  }

  /* State Variables */
  uint256 private immutable i_entranceFee; // i for immutable
  VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
  bytes32 private immutable i_gasLane;
  uint64 private immutable i_subscriptionId;
  uint16 private constant REQUEST_CONFIRMATIONS = 3;
  uint32 private immutable i_callbackGasLimit;
  uint32 private constant NUM_WORDS = 1;

  /* Lottery Variables */
  address payable s_recentWinner;
  address payable[] private s_players; // s for storage
  LotteryState private s_lotteryState;
  uint256 private s_lastTimestamp;
  uint256 private immutable i_interval;

  /* Events */
  event LotteryEnter(address indexed player);
  event RequestedLotteryWinner(uint256 indexed requestId);
  event WinnerPicked(address indexed player);

  /* Functions */

  /**
   * @dev VRFConsumerBaseV2 take an address in his constructor, this is why we take the vrfCoordinatorV2 parameter in the Lottery Constructor
   */
  constructor(
    address vrfCoordinatorV2,
    uint64 subscriptionId,
    bytes32 gasLane,
    uint256 interval,
    uint256 _entranceFee,
    uint32 callbackGasLimit
  ) VRFConsumerBaseV2(vrfCoordinatorV2) {
    i_entranceFee = _entranceFee;
    i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    i_gasLane = gasLane;
    i_subscriptionId = subscriptionId;
    i_callbackGasLimit = callbackGasLimit;
    s_lotteryState = LotteryState.OPEN;
    s_lastTimestamp = block.timestamp;
    i_interval = interval;
  }

  function enterLottery() public payable {
    if (msg.value < i_entranceFee) {
      revert Lottery__NotEnoughETHEntered();
    }

    if (s_lotteryState != LotteryState.OPEN) {
      revert Lottery__NotOpen();
    }

    s_players.push(payable(msg.sender));
    emit LotteryEnter(msg.sender);
  }

  /**
   * @dev This is the function that ChainLink automation will call to see if the performUpkeep should be call.
   * Following need to be true to return true :
   *  1 - Our time interval have passed
   *  2 - The lottery should have at least 1 player and ETH
   *  3 - Our subscription is funded with LINK
   *  4 - The lottery should be in a OPEN state
   */
  function checkUpkeep(
    bytes memory /* checkData */
  )
    public
    view
    override
    returns (bool upkeepNeeded, bytes memory /*performData*/)
  {
    bool isOpen = s_lotteryState == LotteryState.OPEN;
    bool timePassed = ((block.timestamp - s_lastTimestamp) > i_interval);
    bool hasPlayers = s_players.length > 0;
    upkeepNeeded = (isOpen && timePassed && hasPlayers);

    return (upkeepNeeded, '0x0');
  }

  /**
   * @dev This function will be called after the checkUpkeep in case of upkeepNeeded is true
   */
  function performUpkeep(bytes calldata /*performData*/) external override {
    (bool upkeepNeeded, ) = checkUpkeep('');
    if (!upkeepNeeded) {
      revert Lottery__UpkeepNotNeeded(
        address(this).balance,
        s_players.length,
        uint256(s_lotteryState)
      );
    }

    s_lotteryState = LotteryState.CALCULATING;

    // Request the random number to the VRF
    uint256 requestId = i_vrfCoordinator.requestRandomWords(
      i_gasLane,
      i_subscriptionId,
      REQUEST_CONFIRMATIONS,
      i_callbackGasLimit,
      NUM_WORDS
    );

    emit RequestedLotteryWinner(requestId);
  }

  /**
   * @dev Callback which handle the random values after they are returned to your contract by the VRF coordinator.
   */
  function fulfillRandomWords(
    uint256 /* requestId */,
    uint256[] memory randomWords
  ) internal override {
    uint256 indexOfWinner = randomWords[0] % s_players.length;
    address payable recentWinner = s_players[indexOfWinner];
    s_recentWinner = recentWinner;
    s_lotteryState = LotteryState.OPEN;
    s_players = new address payable[](0);
    s_lastTimestamp = block.timestamp;
    (bool success, ) = recentWinner.call{value: address(this).balance}('');
    if (!success) {
      revert Lottery__TransfertFailed();
    }

    emit WinnerPicked(recentWinner);
  }

  /* View / Pure functions */
  function getEntranceFee() public view returns (uint256) {
    return i_entranceFee;
  }

  function getPlayer(uint256 index) public view returns (address) {
    return s_players[index];
  }

  function getRecentWinner() public view returns (address payable) {
    return s_recentWinner;
  }

  function getLotteryState() public view returns (LotteryState) {
    return s_lotteryState;
  }

  function getNumberOfPlayers() public view returns (uint256) {
    return s_players.length;
  }

  function getLatestTimestamp() public view returns (uint256) {
    return s_lastTimestamp;
  }

  function getInterval() public view returns (uint256) {
    return i_interval;
  }

  function getSubscriptionId() public view returns (uint256) {
    return i_subscriptionId;
  }

  function getGasLane() public view returns (bytes32) {
    return i_gasLane;
  }

  function getCallbackGasLimit() public view returns (uint256) {
    return i_callbackGasLimit;
  }
}
