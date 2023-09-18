// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "../interfaces/IOracle.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Oracle is IOracle {
    AggregatorV3Interface immutable priceFeed;

    constructor(AggregatorV3Interface _priceFeed) {
        priceFeed = _priceFeed;
    }

    function getEthPrice() external view override returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }
}
