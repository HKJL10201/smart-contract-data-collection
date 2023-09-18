// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceOracle {
    AggregatorV3Interface ethUsdPriceFeed;

    constructor(address _ethUsdPriceFeed) {
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
    }

    function getLatestEthPrice() internal view returns (uint8, uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint8 decimals = ethUsdPriceFeed.decimals();

        return (decimals, uint256(price));
    }

    function convertWeiToUsd(uint256 weiValue)
        internal
        view
        returns (uint8, uint256)
    {
        (uint8 decimals, uint256 ethPrice) = getLatestEthPrice();

        uint256 weiConvertedToUsd = (weiValue * ethPrice) / 10**18;

        return (decimals, weiConvertedToUsd);
    }

    function convertUsdToWei(uint8 inputDecimals, uint256 usd)
        internal
        view
        returns (uint256)
    {
        (uint8 rateDecimals, uint256 ethPrice) = getLatestEthPrice();

        uint256 usdConvertedToWei = (usd * 10**(18 + rateDecimals)) /
            (ethPrice * 10**(inputDecimals));

        return usdConvertedToWei;
    }
}
