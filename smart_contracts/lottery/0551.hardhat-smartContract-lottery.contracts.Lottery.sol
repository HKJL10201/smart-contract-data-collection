// Lottery
// Enter the lottery (paying some amount)
// Pick a random winner (verifiable random)
// Winner to be selected every X minutes -> completly automated
// Chainlink Oracle -> Ramdomness , Automated Execution (Chainlink keepers)

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "hardhat/console.sol";

error Lottery__NotEnoughETHEntered();
error Lottery__TransferFailed();
error Lottery__NotOpen();
error Lottery__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayer, uint256 lotteryState);

/**@title A sample Lottery Contract
 * @author Muhammmet isik
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */
contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
  /* type declarations */
  enum LotteryState {
    OPEN,
    CALCULATING
  } // uint256 0 = OPEN, 1 = CACULATING

  /* State variables */
  uint256 private immutable i_entranceFee;
  address payable[] private s_players;
  VRFCoordinatorV2Interface private immutable i_vrfcoordinator;
  bytes32 private immutable i_gasLane;
  uint64 private immutable i_subscriptionId;
  uint32 private immutable i_callbackGasLimit;
  uint16 private constant REQUEST_CONFIRMATOINS = 3;
  uint32 private constant NUM_WORDS = 1;

  /* Events */
  event LotteryEnter(address indexed player);
  event RequestLotteryWinner(uint256 indexed requestId);
  event WinnerPicked(address indexed Winner);

  // Lottery variables
  address private s_recentWinner;
  LotteryState private s_lotteryState;
  uint256 private s_lastTimeStamp;
  uint256 private immutable i_interval;

  constructor(
    address vrfCoordinatorV2,
    uint64 subscriptionId,
    bytes32 gasLane, // keyHash
    uint256 interval,
    uint256 entranceFee,
    uint32 callbackGasLimit
  ) VRFConsumerBaseV2(vrfCoordinatorV2) {
    i_entranceFee = entranceFee;
    i_vrfcoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    i_gasLane = gasLane;
    i_subscriptionId = subscriptionId;
    i_callbackGasLimit = callbackGasLimit;
    s_lotteryState = LotteryState.OPEN;
    s_lastTimeStamp = block.timestamp;
    i_interval = interval;
  }

  function enterLottery() public payable {
    // require (msg.value > i_entranceFee , " Not Enough ETH!")
    if (msg.value < i_entranceFee) {
      revert Lottery__NotEnoughETHEntered();
    }
    if (s_lotteryState != LotteryState.OPEN) {
      revert Lottery__NotOpen();
    }
    s_players.push(payable(msg.sender));
    emit LotteryEnter(msg.sender);
    // emit an Events when we update dynamic array or mapping
  }

  /**
   * @dev This is the function that the Chainlink Keeper nodes call
   * they look for `upkeepNeeded` to return True.
   * the following should be true for this to return true:
   * 1. The time interval has passed between raffle runs.
   * 2. The lottery is open.
   * 3. The contract has ETH.
   * 4. Implicity, your subscription is funded with LINK.
   */

  function checkUpkeep(
    bytes memory /*checkData*/
  ) public override returns (bool upkeepNeeded, bytes memory /* performData */) {
    bool isOpen = (LotteryState.OPEN == s_lotteryState);
    bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
    bool hasPlayers = (s_players.length > 0);
    bool hasBalance = (address(this).balance > 0);
    upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
    return (upkeepNeeded, "0x0");
  }

  function performUpkeep(bytes calldata /*performData*/) external override {
    // request the random numbers
    // Once we get it, do some thing with it
    // 2 transaction process
    (bool upkeepNeeded, ) = checkUpkeep("");
    if (!upkeepNeeded) {
      revert Lottery__UpkeepNotNeeded(
        address(this).balance,
        s_players.length,
        uint256(s_lotteryState)
      );
    }
    s_lotteryState = LotteryState.CALCULATING;
    uint256 requestId = i_vrfcoordinator.requestRandomWords(
      i_gasLane,
      i_subscriptionId,
      REQUEST_CONFIRMATOINS,
      i_callbackGasLimit,
      NUM_WORDS
    );
    emit RequestLotteryWinner(requestId);
  }

  function fulfillRandomWords(
    uint256 /*requestId*/,
    uint256[] memory randomWords
  ) internal override {
    uint256 indexOfWinner = randomWords[0] % s_players.length;
    address payable recentWinner = s_players[indexOfWinner];
    s_recentWinner = recentWinner;
    s_lotteryState = LotteryState.OPEN;
    s_players = new address payable[](0);
    s_lastTimeStamp = block.timestamp;
    (bool success, ) = recentWinner.call{value: address(this).balance}("");
    if (!success) {
      revert Lottery__TransferFailed();
    }
    emit WinnerPicked(recentWinner);
  }

  /* View / pure functions */
  function getEntranceFee() public view returns (uint256) {
    return i_entranceFee;
  }

  function getPlayer(uint256 index) public view returns (address) {
    return s_players[index];
  }

  function getRecentWinner() public view returns (address) {
    return s_recentWinner;
  }

  function getLotteryState() public view returns (LotteryState) {
    return s_lotteryState;
  }

  function getNumWord() public pure returns (uint256) {
    return NUM_WORDS;
  }

  function getNumPlayers() public view returns (uint256) {
    return s_players.length;
  }

  function getLatestTimeStamp() public view returns (uint256) {
    return s_lastTimeStamp;
  }

  function getRequestConfirmations() public pure returns (uint256) {
    return REQUEST_CONFIRMATOINS;
  }

  function getInterval() public view returns (uint256) {
    return i_interval;
  }
}
