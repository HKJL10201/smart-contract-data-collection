// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter { 
    //Can't have state vars
    //Can't send ether 

     //get the converion rate of ETH in terms of USD 
    function getPrice(AggregatorV3Interface priceFeed)   internal view returns(uint256) { 
         //call the latestround data on the price feed
         //All we want is the latest price
         (, int256 price, , , ) = priceFeed.latestRoundData();    
         //Eth in terms of USD
         return uint256(price * 1e10); //1*10 = 1000000000
    }

    function getVersion()   internal view returns(uint256) { 
        //ABI
        //ADDRESS 	0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version(); 
    }

    function getConverstionRate(uint256 ethAmount, AggregatorV3Interface priceFeed )  internal view returns (uint256) { 
        uint256 ethPrice = getPrice(priceFeed); //call get price for price of ETH 
        uint256 ethAmountinUSD = (ethPrice * ethAmount) / 10**18;  //Math in solidity always multiply then divide
        return ethAmountinUSD;

    }

}