// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
  address payable[] public palyers;
  address payable public recentWinner;
  uint256 public randomness;
  uint256 public usdEntryFee;
  AggregatorV3Interface internal ethUsdPriceFeed;

  enum LOTTERY_STATE {
    OPEN,
    CLOSED,
    CALCULATING_WINNER
  }
  // LOTTERY_STATE is a type.
  // OPEN, CLOSED, CALCULATING_WINNER = 0,1,2

  LOTTERY_STATE public lottery_state;
  uint256 public fee;
  bytes32 public keyhash;
  event RequestedRandomness(bytes32 requestId);

  constructor(
    address _priceFeedAddress,
    address _vrfCoordinator,
    address _link,
    uint256 _fee,
    bytes32 _keyhash
  ) public VRFConsumerBase(_vrfCoordinator, _link) {
    usdEntryFee = 50 * (10**18);
    ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
    lottery_state = LOTTERY_STATE.CLOSED;
    // We can also set it CLOSED like this: lottery_state = 1
    fee = _fee;
    keyhash = _keyhash;
  }

  function enter() public payable {
    // 50$ minimum
    require(lottery_state == LOTTERY_STATE.OPEN);
    require(msg.value >= getEnteranceFee(), "Not enough Eth!");
    palyers.push(msg.sender);
  }

  function getEnteranceFee() public view returns (uint256) {
    (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
    uint256 adjustedPrice = uint256(price) * 10**10; //18 decimals
    uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
    return costToEnter;
  }

  function startLottery() public onlyOwner {
    require(
      lottery_state == LOTTERY_STATE.CLOSED,
      "Can't start a new lottery yet!"
    );
    lottery_state = LOTTERY_STATE.OPEN;
  }

  function endLottery() public onlyOwner {
    lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
    bytes32 requestId = requestRandomness(keyhash, fee);
    emit RequestedRandomness(requestId);
  }

  function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
    internal
    override
  {
    require(
      lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
      "you aren't there yet"
    );
    require(_randomness > 0, "No random number found");
    uint256 indexOfWinner = _randomness % palyers.length;
    recentWinner = palyers[indexOfWinner];
    recentWinner.transfer(address(this).balance);

    //Rest
    palyers = new address payable[](0);
    lottery_state = LOTTERY_STATE.CLOSED;
    randomness = _randomness;
  }
}
