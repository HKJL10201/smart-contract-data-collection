// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable {
    address payable[] public players;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    constructor(address _priceFeedAddress) public {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function enter() public payable {
        // $50 dollars entrance fee
        require(lottery_state == LOTTERY_STATE.OPEN)
        require(msg.value >= getEntranceFee(), "Not Enough ETH");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        //
        (,int price, ,,) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10 ** 10; // 18 decimals
        uint256 costToEnter = (usdEntryFee * 10 ** 18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public OnlyOwner {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Can's start a new lottery yet!");
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public OnlyOwner {}
}
