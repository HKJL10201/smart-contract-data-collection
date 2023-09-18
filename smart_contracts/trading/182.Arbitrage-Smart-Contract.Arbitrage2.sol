// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IPancakeRouter {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IdYdX {
    function trade(
        address market,
        uint256 positionId,
        address trader,
        address receiver,
        uint256 amount,
        uint256 data
    ) external;
}

contract Arbitrage {
    address public tokenToTrade;
    address public uniswapRouter;
    address public pancakeRouter;
    address public dydx;

    constructor(address _tokenToTrade, address _uniswapRouter, address _pancakeRouter, address _dydx) {
        tokenToTrade = _tokenToTrade;
        uniswapRouter = _uniswapRouter;
        pancakeRouter = _pancakeRouter;
        dydx = _dydx;
    }

    function startArbitrage(uint amountIn) external {
        address[] memory path = new address[](2);
        path[0] = tokenToTrade;
        path[1] = 0xc778417E063141139Fce010982780140Aa0cD5Ab; // WETH address on Ethereum

        uint[] memory amounts = IUniswapV2Router(uniswapRouter).getAmountsOut(amountIn, path);
        uint amountOut = amounts[1];

        IUniswapV2Router(uniswapRouter).swapExactTokensForTokens(amountIn, amountOut, path, address(this), block.timestamp + 1800);

        address[] memory path1 = new address[](2);
        path1[0] = tokenToTrade;
        path1[1] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB address on Binance Smart Chain

        uint[] memory amounts1 = IPancakeRouter(pancakeRouter).getAmountsOut(amountIn, path1);
        uint amountOut1 = amounts1[1];

        IPancakeRouter(pancakeRouter).swapExactTokensForTokens(amountIn, amountOut1, path1, address(this), block.timestamp + 1800);

        uint data = 0;
        IdYdX(dydx).trade(
            0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e,
            1,
            address(this),
            address(this),
            amountIn,
            data
        );
    }
}
