pragma solidity ^0.6.12;

contract TestUniswapOracle {
  function update() external returns (bool success) {
    return true;
  }

  function consult(address token, uint256 amountIn)
    external
    view
    returns (uint256 amountOut)
  {
    return 10**15; // 1 USDC = 0.001 ETH
  }
}
