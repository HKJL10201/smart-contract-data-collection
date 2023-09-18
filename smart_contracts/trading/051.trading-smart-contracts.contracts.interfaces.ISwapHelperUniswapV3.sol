// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface ISwapHelperUniswapV3 {
    /**
     * @notice Emitted when seconds ago default updated
     * @param value The new param secondsAgoDefault
     */
    event SecondsAgoDefaultUpdated(uint32 value);

    /**
     * @notice Emitted when slippage updated
     * @param value The new slippage value, where 100% = 1000000
     */
    event SlippageUpdated(uint256 value);

    /**
     * @notice Emitted when swap confirmed
     * @param beneficiary Beneficiary output tokens after swap
     * @param tokenIn  Exchangeable token
     * @param tokenOut The other of the two tokens in the desired pool
     * @param amountIn The desired number of tokens for the exchange
     * @param amountOut Average number of tokens `amountOut` in the selected
     * time interval from the current moment and the pool
     */
    event Swapped(
        address indexed beneficiary,
        address indexed tokenIn,
        address indexed tokenOut,
        uint128 amountIn,
        uint256 amountOut
    );

    /**
     * @notice Get the minimum number of tokens for a subsequent swap, taking into account slippage
     * @param tokenIn One of the two tokens in the desired pool
     * @param tokenOut The other of the two tokens in the desired pool
     * @param amountIn The desired number of tokens for the exchange
     * @param fee The desired fee for the pool
     * @param secondsAgo The number of seconds from the current moment to calculate the average price
     * @dev tokenIn and tokenOut may be passed in either order: token0/token1 or token1/token0.
     * The call will revert if the pool not already exists, the fee is invalid, or the token arguments
     * are invalid. The minimum price is determined by a globally set parameter `_slippage`
     * @return amountOut Average number of tokens `amountOut` in the selected time interval from the current
     * moment and the pool
     */
    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint24 fee,
        uint32 secondsAgo
    ) external view returns (uint256 amountOut);

    /**
     * @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
     * @param beneficiary Beneficiary `amountOut` after swap
     * @param tokenIn Exchangeable token
     * @param tokenOut Output token during the exchange
     * @param amountIn The desired number of tokens for the exchange
     * @param fee The desired fee for the pool
     * @dev tokenIn and tokenOut may be passed in either order: token0/token1 or token1/token0.
     * The call will revert if the pool not already exists, the fee is invalid, or the token arguments
     * are invalid. The minimum price is determined by a globally set parameter `_slippage`
     * @return amountOut The number of tokens at the exit after the swap
     */
    function swap(
        address beneficiary,
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint24 fee
    ) external returns (uint256 amountOut);

    /**
     * @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
     * @param beneficiary Beneficiary `amountOut` after swap
     * @param tokenIn Exchangeable token
     * @param tokenOut Output token during the exchange
     * @param amountIn The desired number of tokens for the exchange
     * @param fee The desired fee for the pool
     * @param slippageForSwap slippage for swap
     * @dev tokenIn and tokenOut may be passed in either order: token0/token1 or token1/token0.
     * The call will revert if the pool not already exists, the fee is invalid, or the token arguments
     * are invalid. The minimum price is determined by a globally set parameter `_slippage`
     * @return amountOut The number of tokens at the exit after the swap
     */
    function swapWithCustomSlippage(
        address beneficiary,
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint24 fee,
        uint256 slippageForSwap
    ) external returns (uint256 amountOut);
}
