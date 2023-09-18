// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "../dataTypes/UniswapInputTypes.sol";

interface IMinimalSwapRouter {
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    function exactInput(ExactInputParams memory params) external payable returns (uint256 amountOut);

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    function exactInputToSelf(MinimalExactInputMultiParams memory params) external payable returns (uint256 amountOut);

    function exactOutputToSelf(MinimalExactOutputMultiParams calldata params) external payable returns (uint256 amountIn);

    function exactInputAndUnwrap(ExactInputParams memory params) external payable returns (uint256 amountOut);

    function exactInputToSelfWithLimit(ExactInputMultiParams memory params) external payable returns (uint256 amountOut);

    function exactOutputToSelfWithLimit(ExactOutputMultiParams calldata params) external payable returns (uint256 amountIn);
}
