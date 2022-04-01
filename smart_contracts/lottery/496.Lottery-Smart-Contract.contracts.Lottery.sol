// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract Lottery {
    // Address Array for storing the players of the lottery
    address payable[] public players;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUSDPriceFeed;

    // Constructor
    constructor(address _priceFeedAddress) public {
        usdEntryFee = 50 * (10**18);
        ethUSDPriceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function enter() public payable {
        // minimum fee - $50
        players.push(msg.sender);
    }

    function getEntrenceFee() public view returns (uint256) {
        (, int256 price, , , , ) = ethUSDPriceFeed.latestRoundData;
        // Process to get the proper price
        // $50, $2000 / ETH
        // 50/2000 : Wrong
        // 50 * 1000000 / 2000 : correct way
        uint256 adjustedPrice = uint256(price) * 10**10; // price in uint256 (18 decimals)
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public {}

    function endLottery() public {}
}
