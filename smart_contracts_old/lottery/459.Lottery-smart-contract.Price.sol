// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    constructor() {
        //Rinkeby network
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    }

    function getPriceRate() public view returns (uint) {
        (, int price,,,) = priceFeed.latestRoundData();
        uint adjust_price = uint(price) * 1e10;
        uint usd = 50 * 1e18;
        uint rate = (usd * 1e18) / adjust_price;
        return rate;
    }
}
