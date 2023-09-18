// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChillieToken {
    function uniswapV2Router() external view returns (address);
    function uniswapV2Pair() external view returns (address);
    function walletAddToLiquidityStash(uint256 amount) external returns (bool);
    function maxTokenAmount() external pure returns (uint256);

    function walletBuyTokens(uint256 ethAmount) payable external returns(uint256 tokensReceived);
    function walletAddLiquidity(uint256 tokenAmount, uint256 ethAmount) payable external returns(bool);

    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}
