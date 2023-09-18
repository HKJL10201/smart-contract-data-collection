// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface IERC20 {
     function approve(address spender, uint rawAmount) external returns (bool);
     function balanceOf(address _owner) external view returns (uint256 balance); 
     function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success);
  }
interface IUniswap{
  function addLiquidity(
  address tokenA,
  address tokenB,
  uint amountADesired,
  uint amountBDesired,
  uint amountAMin,
  uint amountBMin,
  address to,
  uint deadline
) external returns (uint amountA, uint amountB, uint liquidity);
function removeLiquidity(
  address tokenA,
  address tokenB,
  uint liquidity,
  uint amountAMin,
  uint amountBMin,
  address to,
  uint deadline
) external returns (uint amountA, uint amountB);
function factory() external pure returns (address);
}
interface IUniswapV2Factory {
   function getPair(address tokenA, address tokenB) external view returns (address pair);
}
