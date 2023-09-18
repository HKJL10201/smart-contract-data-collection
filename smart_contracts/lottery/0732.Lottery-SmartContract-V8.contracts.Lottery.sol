//SPDX-License-identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable {
    // address array for the players
    address[] public players;
    // Data for entrance Fee
    uint256 public usdEntranceFee;
    AggregatorV3Interface internal priceFeed;
    // Enum for the status of the lottery
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    LOTTERY_STATE public lottery_state;

    //Constructor parámeters
    constructor(address _priceFeedAddress) {
        usdEntranceFee = 50 * 10**18;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function enter() public payable {
        //$50
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery Closed!");
        require(msg.value >= getEntranceFee(), "Not enough ETH");
        //require(msg.value >= $50)

        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10;
        // $50, $2,000 / ETH
        // 50/2,000
        // 50 * 10000 / 2000
        uint256 costToEnter = (usdEntranceFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "the lottery is not closed!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public {}
}
