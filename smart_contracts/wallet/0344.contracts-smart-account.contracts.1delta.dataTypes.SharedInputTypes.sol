// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

struct ExactInputMultiParams {
    bytes path;
    uint256 amountIn;
    uint256 amountOutMinimum;
}

struct ExactOutputMultiParams {
    bytes path;
    uint256 amountOut;
    uint256 amountInMaximum;
}

struct MinimalExactInputMultiParams {
    bytes path;
    uint256 amountIn;
}

struct MinimalExactOutputMultiParams {
    bytes path;
    uint256 amountOut;
}
