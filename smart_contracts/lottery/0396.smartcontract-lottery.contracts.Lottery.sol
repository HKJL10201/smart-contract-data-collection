// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

// AggregatorV3Interface is a contract (.sol).
// It's constructor takes a pricefeed (ETH/USD) address from
// https://docs.chain.link/data-feeds/price-feeds/addresses
contract Lottery {
    address payable[] public players;
    uint256 public entryFeeUsd;
    AggregatorV3Interface internal ethUsdPriceFeed;
    
    constructor(address _priceFeedAddress) public {
        entryFeeUsd = 50 * (10**18);  // usd 18 decimal places
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);  // ETH/USD
    }
    
    function enter() public payable{
        players.push(msg.sender);
    }
        
    // Ether = Wei / 10^18
    // Wei = Ether * 10^18

    // price feed has 8 decimal places.
    // Move decimal point to the right 10 more times. price * 10**10 = 18 (adjustedPrice).
    function getCurrentEthPriceInWei() public view returns (uint256) {
        (, int256 price,,,) = ethUsdPriceFeed.latestRoundData();  // get current price of ETH (8 decimal places)
        // price = 2000 * 10**8; round number for test only
        uint256 adjustedPriceInWei = uint256(price) * 10**10;  // add 10 more decimal places to have 18 decimal places
        return adjustedPriceInWei;  // in wei 
    }

    // return 50 dollars with 18 decimal places
    function getEntranceFeeInUsd() public view returns (uint256) {
        return entryFeeUsd;
    }
    
    // return 50 dollars worth of ETH in wei 
    function getEntranceFeeInWei() public view returns (uint256) {
        uint256 currentEthPriceInWei = getCurrentEthPriceInWei();  // in wei, 18 decimal places
        uint256 costToEnterInWei = (entryFeeUsd * 10**18) / currentEthPriceInWei ;  // 50 usd / 2000 eth
        return costToEnterInWei;  // in wei 
    }

    function startLottery() public {}
    
    function endLottery() public {}
}