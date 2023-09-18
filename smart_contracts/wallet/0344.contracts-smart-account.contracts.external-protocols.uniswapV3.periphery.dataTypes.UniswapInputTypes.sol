// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import {
    ExactOutputMultiParams,
    ExactInputMultiParams,
    MinimalExactOutputMultiParams,
    MinimalExactInputMultiParams
} from "../../../../1delta/dataTypes/SharedInputTypes.sol";

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
}

struct ExactOutputParams {
    bytes path;
    address recipient;
    uint256 amountOut;
}