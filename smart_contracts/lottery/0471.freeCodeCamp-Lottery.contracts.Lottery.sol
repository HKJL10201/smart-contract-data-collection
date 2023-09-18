// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable, VRFConsumerBase
{
    uint256 public randomness;
    uint256 public fee;
    bytes32 public keyhash;

    enum LOTTERY_STATE
    {
        INIT,
        OPEN, 
        CLOSED,
        CALCULATING_WINNER
    }

    event RequestedRandomness(bytes32 requestID);

    address payable[] public players;
    address payable public recentWinner;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    LOTTERY_STATE public lottery_state;

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) 
    {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.INIT;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable
    {
        // $50 minimum
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery is not opened you idiot!");
        require(msg.value >= getEntranceFee(), "Entrance fee is $50 in ETH!");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256)
    {
        uint256 adjustPrice;
        (,int256 price,,,) = ethUsdPriceFeed.latestRoundData(); // 8 decimals
        adjustPrice = uint256(price) * 10**10; //18 decimals

        // 2000 - 10^18
        // 50 - x

        // x = (50 / 2000) * 10^18

        uint256 costToEnter = (usdEntryFee * 10**18) / adjustPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner
    {
        require(lottery_state == LOTTERY_STATE.INIT, "Can't start a lottery if lottery is ongoing!");
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner
    {
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery is not open!");
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    // callback function for requestRandomNumber() - Receives random values and stores them in your contract.
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override
    {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "Lottery has not been finished yet!");
        require(_randomness > 0, "Random-number-not-found.");

        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);

        // Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.INIT;

        randomness = _randomness;
    }
}