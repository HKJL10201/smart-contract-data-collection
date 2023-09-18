// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// imports

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

// errors
error Raffle__UpkeepNotNeeded(
  uint256 currentBalance,
  uint256 numPlayers,
  uint256 raffleState
);
error Raffle__TransferFailed();
error Raffle__SendMoreToEnterRaffle();
error Raffle__RaffleNotOpen();

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
  // State Variables

  enum RaffleState {
    OPEN,
    FINDING_WINNER
  }

  // Parent Class Variables

  VRFCoordinatorV2Interface private immutable vrfCoordinator;
  uint64 private immutable subscriptionID;
  bytes32 private immutable keyHash; // gaslane
  uint32 private immutable callbackGasLimit;
  uint16 private constant REQ_CONF = 3;
  uint32 private constant NUM_WORDS = 1;

  // Lottery Variables

  uint256 private immutable interval;
  uint256 private lastTimeStamp;
  address private winner;
  uint256 private entranceFee;
  address payable[] private participants;
  RaffleState private state;

  // events
  event RequestedRaffleWinner(uint256 indexed requestId);
  event RaffleEnter(address indexed player);
  event WinnerPicked(address indexed player);

  constructor(
    address _vrfCoordinatorAddress,
    uint64 _subscriptionID,
    bytes32 _keyHash,
    uint32 _callbackGasLimit,
    uint256 _entranceFee,
    uint256 _interval
  ) VRFConsumerBaseV2(_vrfCoordinatorAddress) {
    vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorAddress);
    subscriptionID = _subscriptionID;
    keyHash = _keyHash;
    callbackGasLimit = _callbackGasLimit;
    entranceFee = _entranceFee;
    interval = _interval;
    lastTimeStamp = block.timestamp;
    state = RaffleState.OPEN;
  }

  // Getter functions

  function getRaffleState() public view returns (RaffleState) {
    return state;
  }

  function getEntranceFee() public view returns (uint256) {
    return entranceFee;
  }

  function getNumWords() public pure returns (uint256) {
    return NUM_WORDS;
  }

  function getRecentWinner() public view returns (address) {
    return winner;
  }

  function getPlayer(uint256 index) public view returns (address) {
    return participants[index];
  }

  function getLastTimeStamp() public view returns (uint256) {
    return lastTimeStamp;
  }

  function getInterval() public view returns (uint256) {
    return interval;
  }

  function getNumPlayers() public view returns (uint256) {
    return participants.length;
  }

  function getRequestConfirmation() public pure returns (uint16) {
    return REQ_CONF;
  }

  // functions

  /**
    to enter the raffle
 */

  function enterRaffle() public payable {
    if (msg.value < entranceFee) {
      revert Raffle__SendMoreToEnterRaffle();
    }

    if (state != RaffleState.OPEN) {
      revert Raffle__RaffleNotOpen();
    }

    participants.push(payable(msg.sender));

    emit RaffleEnter(msg.sender);
  }

  function checkUpkeep(
    bytes memory /* checkData */
  )
    public
    view
    override
    returns (
      bool upkeepNeeded,
      bytes memory /* performData */
    )
  {
    bool isOpen = state == RaffleState.OPEN;
    bool timePassed = ((block.timestamp - lastTimeStamp) > interval);
    bool hasParticipants = participants.length > 0;
    bool hasBalance = address(this).balance > 0;
    upkeepNeeded = isOpen && timePassed && hasParticipants && hasBalance;
    return (upkeepNeeded, "0x0");
  }

  function performUpkeep(
    bytes memory /* checkData */
  ) external override {
    (bool upkeedNeeded, ) = checkUpkeep("");
    if (!upkeedNeeded) {
      revert Raffle__UpkeepNotNeeded(
        address(this).balance,
        participants.length,
        uint256(state)
      );
    }

    state = RaffleState.FINDING_WINNER;
    uint256 requestId = vrfCoordinator.requestRandomWords(
      keyHash,
      subscriptionID,
      REQ_CONF,
      callbackGasLimit,
      NUM_WORDS
    );

    emit RequestedRaffleWinner(requestId);
  }

  function fulfillRandomWords(
    uint256, /*requestId*/
    uint256[] memory randomWords
  ) internal override {
    uint256 winnerIndex = randomWords[0] % participants.length;
    address payable recentWinner = participants[winnerIndex];
    winner = recentWinner;
    participants = new address payable[](0);
    state = RaffleState.OPEN;
    lastTimeStamp = block.timestamp;
    (bool callSuccess, ) = recentWinner.call{ value: address(this).balance }(
      ""
    );

    if (!callSuccess) {
      revert Raffle__TransferFailed();
    }
    emit WinnerPicked(recentWinner);
  }
}
