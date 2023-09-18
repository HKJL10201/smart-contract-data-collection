// Raffle
// enter the raffle by paying some amount
// pick a random winner (true random)
// winner to be selected every x minutes
// chainlink oracle -> randomness and automated execution; chainlink keeper and vrf

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughETH();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpKeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
  enum RaffleState {
    OPEN,
    CALCULATING
  } // uint256 ; 0= open 1= calculating
  /**STATE VARIABLES */
  uint256 private immutable i_entranceFee;
  address payable[] private s_players;
  VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
  bytes32 private immutable i_gasLane;
  uint64 private immutable i_subscriptionId;
  uint32 private immutable i_callbackGasLimit;
  uint16 private constant REQUEST_CONFIRMATIONS = 3;
  uint32 private constant NUM_WORDS = 1;

  /**LOTTERY VARIABLES */
  address private s_recentWinner;
  RaffleState private s_raffleState;
  uint256 private s_lastTimeStamp;
  uint256 private immutable i_interval;

  event RaffleEnter(address indexed player);
  event RequestedRaffleWinner(uint256 indexed requestId);
  event WinnerPicked(address indexed winner);

  constructor(
    address vrfCoordinatorV2_, // vrfcoordinator contract address for its interface
    uint256 entranceFee_,
    bytes32 gasLane_,
    uint64 subscriptionId_,
    uint32 callbackGasLimit_,
    uint256 interval_
  )
    VRFConsumerBaseV2(vrfCoordinatorV2_) // vrfconsumerbasev2's constructor also takes arguments
  {
    i_entranceFee = entranceFee_;
    i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2_); // here i instantiate the vrfcoordinator contract
    i_gasLane = gasLane_;
    i_subscriptionId = subscriptionId_;
    i_callbackGasLimit = callbackGasLimit_;
    s_raffleState = RaffleState.OPEN;
    s_lastTimeStamp = block.timestamp;
    i_interval = interval_;
  }

  function enterRaffle() public payable {
    if (msg.value < i_entranceFee) {
      revert Raffle__NotEnoughETH();
    }
    if (s_raffleState != RaffleState.OPEN) {
      revert Raffle__NotOpen();
    }
    s_players.push(payable(msg.sender));
    emit RaffleEnter(msg.sender);
  }

  /**
  @dev checkUpKeep is the function the keeper nodes look for 
   */

  function checkUpkeep(
    // a function from KeeperCompatibleInterface
    bytes memory /*checkData*/
  )
    public
    view
    override
    returns (
      bool upkeepNeeded,
      bytes memory /*performData*/
    )
  {
    bool isOpen = (RaffleState.OPEN == s_raffleState);
    bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
    bool hasPlayers = (s_players.length > 0);
    bool hasBalance = address(this).balance > 0;
    upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    return (upkeepNeeded, "0x0");
  }

  function performUpkeep(
    // this function is triggered automatically when its time it requests the random number
    bytes calldata /**performData */
  ) external override {
    // vrf is a 2 part process here i request the random number
    (bool upkeepNeeded, ) = checkUpkeep("");
    if (!upkeepNeeded) {
      revert Raffle__UpKeepNotNeeded(
        address(this).balance,
        s_players.length,
        uint256(s_raffleState)
      );
    }
    s_raffleState = RaffleState.CALCULATING;
    uint256 requestId = i_vrfCoordinator.requestRandomWords( // requestId will be set automatically by vrfcoordinator
      i_gasLane, // gas limit
      i_subscriptionId, // vrf subscription number
      REQUEST_CONFIRMATIONS, // block confirmations
      i_callbackGasLimit, // gas limit
      NUM_WORDS // the amount of random numbers requested
    );
    emit RequestedRaffleWinner(requestId); // this is redundant, vrf coordinator already does this
  }

  function fulfillRandomWords(
    // a function from vrfconsumerbase
    uint256, /*requestId*/
    uint256[] memory randomWords
  ) internal override {
    uint256 indexOfWinner = randomWords[0] % s_players.length;
    address payable recentWinner = s_players[indexOfWinner];
    s_recentWinner = recentWinner;
    s_raffleState = RaffleState.OPEN;
    s_players = new address payable[](0); // reset the players array
    s_lastTimeStamp = block.timestamp; // reset the timestamp
    (bool success, ) = recentWinner.call{value: address(this).balance}("");
    if (!success) {
      revert Raffle__TransferFailed();
    }
    emit WinnerPicked(recentWinner);
  }

  function getEntranceFee() public view returns (uint256) {
    return i_entranceFee;
  }

  function getPlayer(uint256 index_) public view returns (address) {
    return s_players[index_];
  }

  function getRecentWinner() public view returns (address) {
    return s_recentWinner;
  }

  function getRaffleState() public view returns (uint256) {
    return uint256(s_raffleState);
  }

  function getNumWords() public pure returns (uint256) {
    return NUM_WORDS; // this is pure because it is being read from bytecode and not storage else it would have been view
  }

  function getNumberOfPlayers() public view returns (uint256) {
    return s_players.length;
  }

  function getLatestTimeStamp() public view returns (uint256) {
    return s_lastTimeStamp;
  }

  function getRequestConfirmations() public pure returns (uint256) {
    return REQUEST_CONFIRMATIONS;
  }

  function getInterval() public view returns (uint256) {
    return i_interval;
  }
}
