//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol' ;

library PriceConverter {
  
  /**To get external pricefeed data from chainlink
   * Network chainLink Address
   * ABI
   */
  function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
    (,int256 price,,, ) = priceFeed.latestRoundData();
    
    /**
     * Typecasting to convert to uint256 with 18 decimals
     */
    return uint256(price * 1e10);

  }

  function getVersion() internal view  returns (uint256) {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

    return priceFeed.version();

  }

  function getConversionRate(uint256 _ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
    uint256 ethPrice = getPrice(priceFeed);

    uint256 ethAmountinUSD = (ethPrice * _ethAmount ) / 1e18;

    return ethAmountinUSD;
  }
}