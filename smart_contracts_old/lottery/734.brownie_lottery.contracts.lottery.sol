// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {

    // global variables
    AggregatorV3Interface internal ethUsdPriceFeed;
    address[] public players;
    address public recentWinner;
    uint256 public usdEntryFee;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER}
    LOTTERY_STATE public lotteryState;
    // variables needed to get random number from Chainlink
    bytes32 internal keyHash;
    uint256 internal fee;
    event requestedRandomness(bytes32 requestId);

    // point to oracle, set lottery state and entrance fee
    constructor(
        address _priceFeedAddress, 
        address _vrfCoordinator, 
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lotteryState = LOTTERY_STATE.CLOSED;
        usdEntryFee = 50 * 10 ** 18;
        keyHash = _keyHash;
        fee = _fee;
    }
    
    // let users join the lottery buying a ticket
    function enter() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery is not open!");
        require(msg.value == getEntranceFee(),"Not enough ETH");
        players.push(msg.sender);
    }

    // get ticket price in ETH
    function getEntranceFee() public view returns(uint256) {
        (,int256 price,,,) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10 ** 10;
        return (usdEntryFee * 10 ** 18) / adjustedPrice;
    }

    // let admin start a lottery
    function startLottery() public onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Can't start a new lottery yet!");
        lotteryState = LOTTERY_STATE.OPEN;
    }

    // let admin close the lottery
    function closeLottery() public onlyOwner {
        require(lotteryState == LOTTERY_STATE.OPEN, "No open lottery!");
        // choose winner
        lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit requestedRandomness(requestId);
    }

    // retrieve requested random number from Chainlink
    // this function will be called by the VRFCoordinator that will input the random number (uint256 randomness)
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER, "Not calculating winner");
        require(_randomness > 0, "random not found");
        uint256 winnerIndex = _randomness % players.length;
        recentWinner = players[winnerIndex];
        address payable winner = payable(players[winnerIndex]);
        winner.transfer(address(this).balance);
        // reset lottery
        players = new address[](0);
        lotteryState = LOTTERY_STATE.CLOSED;
    }
}