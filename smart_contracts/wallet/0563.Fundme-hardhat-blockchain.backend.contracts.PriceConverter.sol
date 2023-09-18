// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getLatestPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 eth,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 usdPerEth = getLatestPrice(priceFeed);
        uint256 usd = (usdPerEth * eth) / 1e18;
        return usd;
    }
}
