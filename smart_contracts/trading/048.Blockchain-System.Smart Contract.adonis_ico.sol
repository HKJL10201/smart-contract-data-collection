// Compiler version
pragma solidity ^0.8.7;

contract Adonis_ico 
{
    // Introduce the max number of Adonis coins available for sale
    uint public max_adonis_coins = 1000000;

    // Introduce the USD to Adonis coins conversion rate (1$ = 1000 Adonis coins)
    uint public usd_to_adonis_coins = 1000;

    // Introduce the total number of Adonis coins that have been bought by the investors
    uint public total_adoins_coins_bought = 0;

    // Mapping from the investor address to its equity in Adoins and USD
    mapping(address => uint) equity_adonis_coins;
    mapping(address => uint) equity_usd;

    // Checking if an investor can buy Adonis coins
    modifier can_buy_adonis_coins(uint usd_invested)
    {
        require (usd_invested * usd_to_adonis_coins + total_adoins_coins_bought <= max_adonis_coins);
        _;
    }

    // Getting the equity in Adonis coins of an investor
    function equity_in_adonis_coins(address investor) external returns (uint)
    {
        return equity_adonis_coins[investor];
    }

    // Getting the equity in USD of an investor
    function equity_in_usd(address investor) external returns (uint)
    {
        return equity_usd[investor];
    }

    // Buying Adonis coins
    function buy_adonis_coins(address investor, uint usd_invested) external can_buy_adonis_coins(usd_invested)
    {
        uint adonis_coins_bought = usd_invested * usd_to_adonis_coins;
        equity_adonis_coins[investor] += adonis_coins_bought;
        // We divide it by 1000 because we defined the conversion rate as 1$ = 1000 Adonis coins
        equity_usd[investor] = equity_adonis_coins[investor] / 1000;
        total_adoins_coins_bought += adonis_coins_bought;
    }

    // Selling Adonis coins
    function sell_adonis_coins(address investor, uint adonis_coins_sold) external
    {
        equity_adonis_coins[investor] -= adonis_coins_sold;
        // We divide it by 1000 because we defined the conversion rate as 1$ = 1000 Adonis coins
        equity_usd[investor] = equity_adonis_coins[investor] / 1000;
        total_adoins_coins_bought -= adonis_coins_sold;
    }
}