// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Lottery is Ownable, VRFConsumerBaseV2 {

  address payable[] public players;
  uint256 public entryFee;
  address payable public recentWinner;
  uint256 public randomness;
  enum LOTTERY_STATE {
    OPEN,
    CLOSED,
    CALCULATING_WINNER
  }

  LOTTERY_STATE public lottery_state;

  /*
  *   For Chainlink VRF
  */

  VRFCoordinatorV2Interface COORDINATOR;
  uint64 s_subscriptionId; // Your subscription ID.
  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab; // Rinkeby coordinator
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3; // The default is 3, but you can set this higher.
  uint32 numWords =  1; // retrieve 1 random value in one request.

  uint256[] public s_randomWords;
  uint256 public s_requestId;

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    entryFee = 0.001 * (10**18);
    lottery_state = LOTTERY_STATE.CLOSED;

    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_subscriptionId = subscriptionId;
  }

  function enter() public payable {
    require(lottery_state == LOTTERY_STATE.OPEN, "Lottery state is Closed");
    require(msg.value >= getEntryFee(), "Not enough ETH");
    players.push() = payable(msg.sender);
  }

  function getEntryFee() public view returns (uint256) {
    return entryFee;
  }

  function starLottery() public onlyOwner {
    require(lottery_state == LOTTERY_STATE.CLOSED, "Can't start a new lottery yet");
    lottery_state = LOTTERY_STATE.OPEN;

  }

  function endLottery() public onlyOwner {

    lottery_state = LOTTERY_STATE.CALCULATING_WINNER;

    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

  function fulfillRandomWords(uint256, /* requestId */ uint256[] memory randomWords) internal override {
    require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't there yet");
    require(randomWords[0] > 0, "Random not found");

    uint256 indexOfWinner = randomWords[0] % players.length;
    recentWinner = players[indexOfWinner];
    recentWinner.transfer(address(this).balance);
    players = new address payable[](0);
    lottery_state = LOTTERY_STATE.CLOSED;
    randomness = randomWords[0];
  }
}