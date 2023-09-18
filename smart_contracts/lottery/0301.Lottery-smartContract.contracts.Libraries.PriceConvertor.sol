// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// library for getting track of price feeds with chainlink oracles

library PriceConvertor {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // get price of ETH/USD
        (, int256 price, , , ) = priceFeed.latestRoundData(); // this function returns price with 8 decimals

        // return price with 18 decimals
        return uint256(price * 1e10);
    }

    function getConvertedPrice(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 convertedEthToUsd = (ethPrice * ethAmount) / 1e18;

        return convertedEthToUsd;
    }
}
