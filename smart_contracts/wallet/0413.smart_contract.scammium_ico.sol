// Scammium ICO

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract scammium_ico {

    // Total Scammium for sale
    uint public max_scammium = 1000000;

    // USD to Scammium conversion rate
    uint public usd_to_scammium = 1000;

    // Total Scammium bought by investors
    uint public total_scammium_bought = 0;

    // Mapping investor address to equity in Scammium and USD
    mapping(address => uint) equity_scammium;
    mapping(address => uint) equity_usd;

    // Check if investor can buy Scammium
    modifier can_buy_scammium(uint usd_invested) {
        require (usd_invested * usd_to_scammium + total_scammium_bought <= max_scammium);
        _;
    }

    // Get investor equity in Scammium
    function equity_in_scammium(address investor) external view returns(uint) {
        return equity_scammium[investor];
    }

    // Get investor equity in USD
    function equity_in_usd(address investor) external view returns(uint) {
        return equity_usd[investor];
    }

    // Buy Scammium
    function buy_scammium(address investor, uint usd_invested) external can_buy_scammium(usd_invested) {
        require (equity_usd[investor] >= usd_invested);
        uint scammium_bought = usd_invested * usd_to_scammium;
        equity_scammium[investor] += scammium_bought;
        equity_usd[investor] -= usd_invested;
        total_scammium_bought += scammium_bought;
    }

    // Sell Scammium
    function sell_scammium(address investor, uint scammium_sold) external {
        require (equity_scammium[investor] >= scammium_sold);
        equity_scammium[investor] -= scammium_sold;
        equity_usd[investor] += usd_to_scammium * scammium_sold;
        total_scammium_bought -= scammium_sold;
    }

}