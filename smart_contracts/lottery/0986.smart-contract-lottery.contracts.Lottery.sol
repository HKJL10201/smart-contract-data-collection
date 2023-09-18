// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
// import "../node_modules/@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "../node_modules/@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";


contract Lottery is VRFConsumerBase, Ownable {
  address payable[] public players;
  address payable public recentWinner;
  uint256 public randomness;
  uint256 public usdEntryFee;
  AggregatorV3Interface internal ethUsdPriceFeed;

  enum LOTTERY_STATE {
    OPEN,
    CLOSED,
    CALCULATING_WINNER
  }
  LOTTERY_STATE public lottery_state;
  uint256 public fee;
  bytes32 public keyhash;
  event RequestedRandomness(bytes32 requestId);
  // 0
  // 1
  // 2
  constructor(
    address _priceFeedAddress,
    address _vrfCoordinator,
    address _link,
    uint256 _fee,
    bytes32 _keyhash
    ) VRFConsumerBase(_vrfCoordinator, _link) {
    usdEntryFee = 50 * (10**18);
    ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
    lottery_state = LOTTERY_STATE.CLOSED;
    fee = _fee;
    keyhash = _keyhash;
  }


  function enter() public payable{
    require(msg.value >= getEntranceFee(), "Not enough ETH");
    require(lottery_state == LOTTERY_STATE.OPEN);
    // $50 minimum
    players.push(payable(msg.sender));
  }
  function getEntranceFee() public view returns(uint256) {
    (, int256 price, , ,) = ethUsdPriceFeed.latestRoundData();
    uint256 adjustedPrice = uint256(price) * 10**10;

    uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
    return costToEnter;
  }
  function startLottery() public onlyOwner{
    require(lottery_state == LOTTERY_STATE.CLOSED, "can't start a new lottery state yet"
    );
    lottery_state = LOTTERY_STATE.OPEN;
  }


  function endLottery() public  onlyOwner {
    // pseudo-random
    // uint256(
    //   keccak256(
    //     abi.encodePacked(
    //       nonce, 
    //       msg.sender,
    //       block.difficulty,
    //       block.timestamp
    //       )
    //     )
    //   ) % players.length;

    // chailink vrf, verifiably randomness function
    lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
    bytes32 requestId = requestRandomness(keyhash, fee);
    emit RequestedRandomness(requestId);
  } 

  function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
    require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "you aren't there yet");
    require(_randomness > 0, "random-not-found");
    uint256 indexOfWinner = _randomness % players.length;
    recentWinner = players[indexOfWinner];
    recentWinner.transfer(address(this).balance);
    
    // reset and create a new brand new players array with a size zero
    players = new address payable[](0);
    lottery_state = LOTTERY_STATE.CLOSED;
    randomness = _randomness;
  }
}