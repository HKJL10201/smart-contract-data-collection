// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable, VRFConsumerBase {

    address payable[] public players;
    uint256 public usdEntranceFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lotteryState;
    uint256 public fee;
    bytes32 public keyhash;
    address payable public latestWinner;
    uint256 public latestRandomNumber;
    event RequestedRandomNumber(bytes32 requestId);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntranceFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lotteryState = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    // Allows a player to enter the lottery by paying the entrance fee.
    function enter() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery is not open.");
        require(msg.value >= getEntranceFee(), "Insufficient funds to enter the lottery");
        players.push(payable(msg.sender));
    }

    // Calculates the entrance fee in ETH using a Chainlink oracle.
    function getEntranceFee() public view returns (uint256) {
        (, int price, ,,) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10;
        uint256 costToEnter = (usdEntranceFee * 10**18) / adjustedPrice;
        return costToEnter;
    }
    
    function startLottery() public onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Lottery is already open.");
        lotteryState = LOTTERY_STATE.OPEN;
    }

    // Ends the lottery and gets a random number from the VRF coordinator.
    function endLottery() public onlyOwner {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery is not open.");
        lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomNumber(requestId);
    }

    // Callback function called by the VRF coordinator when the random number is returned.
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER, "Lottery is not in the calculating winner state.");
        require(_randomness > 0, "A random number was not found.");
        latestRandomNumber = _randomness;
        uint256 winnerIndex = _randomness % players.length;
        latestWinner = players[winnerIndex];
        latestWinner.transfer(address(this).balance);
        players = new address payable[](0);
        lotteryState = LOTTERY_STATE.CLOSED;
    }

}
