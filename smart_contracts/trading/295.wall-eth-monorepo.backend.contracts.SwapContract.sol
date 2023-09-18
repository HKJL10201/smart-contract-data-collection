// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

/* amountOutMinimum: we are setting to zero, but this is a significant risk in production. For a real deployment, this value should be
calculated using our SDK or an onchain price oracle - this helps protect against getting an unusually bad price for a trade due to a
front running sandwich or another type of price manipulation */

/* sqrtPriceLimitX96: We set this to zero - which makes this parameter inactive. In production, this value can be used to set the limit
for the price the swap will push the pool to, which can help protect against price impact or for setting up logic in a variety of
price-relevant mechanisms. */

contract SwapContract {
    ISwapRouter public immutable swapRouter;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint24 public constant feeTier = 3000;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    function swapWETHForDAI(uint amountIn) external returns (uint256 amountOut) {
        // Transfer the specified amount of WETH9 to this contract
        TransferHelper.safeTransferFrom(WETH9, msg.sender, address(this), amountIn);

        // Approve the router to spend WETH9
        TransferHelper.safeApprove(WETH9, address(swapRouter), amountIn);

        // Create the params that will be used to execute the swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: DAI,
            fee: feeTier,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // The call to `exactInputSingle` executes the swap
        amountOut = swapRouter.exactInputSingle(params);

        return amountOut;
    }

    function swapDAIForWETH(uint amountIn) external returns (uint256 amountOut) {
        // Transfer the specified amount of DAI to this contract
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amountIn);

        // Approve the router to spend DAI
        TransferHelper.safeApprove(DAI, address(swapRouter), amountIn);

        // Create the params that will be used to execute the swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: DAI,
            tokenOut: WETH9,
            fee: feeTier,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // The call to `exactInputSingle` executes the swap
        amountOut = swapRouter.exactInputSingle(params);

        return amountOut;
    }
}
