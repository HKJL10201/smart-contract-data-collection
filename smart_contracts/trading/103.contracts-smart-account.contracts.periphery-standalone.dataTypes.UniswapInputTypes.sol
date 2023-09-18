// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {
    ExactOutputMultiParams,
    ExactInputMultiParams,
    MinimalExactOutputMultiParams,
    MinimalExactInputMultiParams
} from "../../1delta/dataTypes/SharedInputTypes.sol";

struct SwapCallbackData {
    bytes path;
    address payer;
}

struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountIn;
    uint160 sqrtPriceLimitX96;
}

struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 amountIn;
}

struct ExactOutputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountOut;
    uint160 sqrtPriceLimitX96;
}

struct ExactOutputParams {
    bytes path;
    address recipient;
    uint256 amountOut;
}