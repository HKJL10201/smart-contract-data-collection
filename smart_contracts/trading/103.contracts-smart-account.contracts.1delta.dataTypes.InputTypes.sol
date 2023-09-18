// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {
    ExactOutputMultiParams,
    ExactInputMultiParams,
    MinimalExactOutputMultiParams,
    MinimalExactInputMultiParams
} from "./SharedInputTypes.sol";

// instead of an enum, we use uint8 to pack the trade type together with user and interestRateMode for a single slot
// the tradeType maps according to the following struct
// enum MarginTradeType {
//     // // One-sided loan and collateral operations
//     // SWAP_BORROW_MULTI_EXACT_IN=2,
//     // SWAP_BORROW_MULTI_EXACT_OUT=3,
//     // SWAP_COLLATERAL_MULTI_EXACT_IN=4,
//     // SWAP_COLLATERAL_MULTI_EXACT_OUT=5,
//     // // Two-sided operations
//     // OPEN_MARGIN_MULTI_EXACT_IN=8,
//     // OPEN_MARGIN_MULTI_EXACT_OUT=9,
//     // TRIM_MARGIN_MULTI_EXACT_IN=10,
//     // TRIM_MARGIN_MULTI_EXACT_OUT=11,
//     // // the following are only used internally
//     // UNISWAP_EXACT_OUT=12,
//     // UNISWAP_EXACT_OUT_BORROW=13,
//     // UNISWAP_EXACT_OUT_WITHDRAW=14
// }

// margin swap input
struct MarginCallbackData {
    bytes path;
    // determines how to interact with the lending protocol
    uint8 tradeType;
    bool exactIn;
}

struct ExactInputSingleParamsBase {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    uint256 amountIn;
    uint256 amountOutMinimum;
}

struct MarginSwapParamsExactIn {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    uint256 amountOutMinimum;
    uint256 amountIn;
}

struct ExactOutputSingleParamsBase {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    uint256 amountOut;
    uint256 amountInMaximum;
}

struct MarginSwapParamsExactOut {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    uint256 amountInMaximum;
    uint256 amountOut;
}

struct MarginSwapParamsMultiExactIn {
    bytes path;
    uint256 amountOutMinimum;
    uint256 amountIn;
}

struct MarginSwapParamsMultiExactOut {
    bytes path;
    uint256 amountInMaximum;
    uint256 amountOut;
}

struct ExactOutputUniswapParams {
    bytes path;
    address recipient;
    uint256 amountOut;
    address user;
    uint256 maximumInputAmount;
    uint8 tradeType;
}

struct ExactInputUniswapParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    address user;
    uint256 amountOutMinimum;
    uint8 tradeType;
}


struct StandaloneExactOutputUniswapParams {
    bytes path;
    address recipient;
    uint256 amountOut;
    uint256 maximumInputAmount;
}

struct StandaloneExactInputUniswapParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
}

// Maximmum payment options

struct CloseParamsExactOutSingle {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    uint256 amountInMaximum;
}

struct CloseMultiExactOut {
    bytes path;
    uint256 amountInMaximum;
}

struct AllInputSingleParamsBase {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    uint256 amountOutMinimum;
}

struct MarginSwapParamsAllIn {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    uint256 amountOutMinimum;
}

struct MarginSwapParamsAllOut {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    uint256 amountInMaximum;
}

struct AllInputMultiParamsBase {
    bytes path;
    uint256 amountOutMinimum;
}

struct AllOutputMultiParamsBase {
    bytes path;
    uint256 amountInMaximum;
}

struct AllInputMultiParamsBaseWithRecipient {
    bytes path;
    address recipient;
    uint256 amountOutMinimum;
}

struct AllOutputMultiParamsBaseWithRecipient {
    bytes path;
    address recipient;
    uint256 amountInMaximum;
}
