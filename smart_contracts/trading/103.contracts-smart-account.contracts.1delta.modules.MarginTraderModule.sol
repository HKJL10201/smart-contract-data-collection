// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.21;

import {IUniswapV3Pool} from "../../external-protocols/uniswapV3/core/interfaces/IUniswapV3Pool.sol";
import "../../external-protocols/uniswapV3/periphery/interfaces/ISwapRouter.sol";
import "../../external-protocols/uniswapV3/core/interfaces/callback/IUniswapV3SwapCallback.sol";
import {Path} from "../dex-tools/uniswap/libraries/Path.sol";
import "../dex-tools/uniswap/libraries/SafeCast.sol";
import {PoolAddressCalculator} from "../dex-tools/uniswap/libraries/PoolAddressCalculator.sol";
import {WithStorage, LibStorage} from "../libraries/LibStorage.sol";
import {BaseSwapper} from "./base/BaseSwapper.sol";

// solhint-disable max-line-length

/**
 * @title MarginTrader contract
 * @notice Allows users to build large margins positions with one contract interaction
 * @author Achthar
 */
contract MarginTraderModule is WithStorage, BaseSwapper {
    using Path for bytes;
    using SafeCast for uint256;

    uint256 private constant DEFAULT_AMOUNT_CACHED = type(uint256).max;

    modifier onlyOwner() {
        LibStorage.enforceAccountOwner();
        _;
    }

    constructor(address _factoryV2, address _factoryV3) BaseSwapper(_factoryV2, _factoryV3) {}

    function swapBorrowExactIn(
        uint256 amountIn,
        uint256 amountOutMinimum,
        bytes calldata path
    ) external onlyOwner returns (uint256 amountOut) {
        (address tokenIn, address tokenOut, uint24 fee) = decodeFirstPool(path);

        bool zeroForOne = tokenIn < tokenOut;

        getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            amountIn.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            path
        );

        amountOut = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        require(amountOutMinimum <= amountOut, "Repaid too little");
    }

    // swaps the loan from one token (tokenIn) to another (tokenOut) provided tokenOut amount
    function swapBorrowExactOut(
        uint256 amountOut,
        uint256 amountInMaximum,
        bytes calldata path
    ) external onlyOwner returns (uint256 amountIn) {
        (address tokenOut, address tokenIn, uint24 fee) = decodeFirstPool(path);

        bool zeroForOne = tokenIn < tokenOut;

        getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            -amountOut.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            path
        );

        amountIn = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        require(amountInMaximum >= amountIn, "Had to borrow too much");
    }

    // swaps the collateral from one token (tokenIn) to another (tokenOut) provided tokenOut amount
    function swapCollateralExactIn(
        uint256 amountIn,
        uint256 amountOutMinimum,
        bytes calldata path
    ) external onlyOwner returns (uint256 amountOut) {
        (address tokenIn, address tokenOut, uint24 fee) = decodeFirstPool(path);
        bool zeroForOne = tokenIn < tokenOut;

        getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            amountIn.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            path
        );

        amountOut = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        require(amountOutMinimum <= amountOut, "Deposited too little");
    }

    // swaps the collateral from one token (tokenIn) to another (tokenOut) provided tokenOut amount
    function swapCollateralExactOut(
        uint256 amountOut,
        uint256 amountInMaximum,
        bytes calldata path
    ) external onlyOwner returns (uint256 amountIn) {
        (address tokenOut, address tokenIn, uint24 fee) = decodeFirstPool(path);

        bool zeroForOne = tokenIn < tokenOut;

        getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            -amountOut.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            path
        );

        amountIn = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        require(amountInMaximum >= amountIn, "Had to withdraw too much");
    }

    // increase the margin position - borrow (tokenIn) and sell it against collateral (tokenOut)
    // the user provides the debt amount as input
    function openMarginPositionExactIn(
        uint256 amountIn,
        uint256 amountOutMinimum,
        bytes calldata path
    ) external onlyOwner returns (uint256 amountOut) {
        (address tokenIn, address tokenOut, uint24 fee) = decodeFirstPool(path);

        bool zeroForOne = tokenIn < tokenOut;
        getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            amountIn.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            path
        );

        amountOut = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        require(amountOutMinimum <= amountOut, "Deposited too little");
    }

    // increase the margin position - borrow (tokenIn) and sell it against collateral (tokenOut)
    // the user provides the collateral amount as input
    function openMarginPositionExactOut(
        uint256 amountOut,
        uint256 amountInMaximum,
        bytes calldata path
    ) external onlyOwner returns (uint256 amountIn) {
        (address tokenOut, address tokenIn, uint24 fee) = decodeFirstPool(path);

        bool zeroForOne = tokenIn < tokenOut;
        getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            -amountOut.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            path
        );

        amountIn = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        require(amountInMaximum >= amountIn, "Had to borrow too much");
    }

    // ================= Trimming Positions ==========================
    // decrease the margin position - use the collateral (tokenIn) to pay back a borrow (tokenOut)
    function trimMarginPositionExactIn(
        uint256 amountIn,
        uint256 amountOutMinimum,
        bytes calldata path
    ) external onlyOwner returns (uint256 amountOut) {
        (address tokenIn, address tokenOut, uint24 fee) = decodeFirstPool(path);

        bool zeroForOne = tokenIn < tokenOut;
        getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            amountIn.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            path
        );

        amountOut = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        require(amountOutMinimum <= amountOut, "Repaid too little");
    }

    function trimMarginPositionExactOut(
        uint256 amountOut,
        uint256 amountInMaximum,
        bytes calldata path
    ) external onlyOwner returns (uint256 amountIn) {
        (address tokenOut, address tokenIn, uint24 fee) = decodeFirstPool(path);

        bool zeroForOne = tokenIn < tokenOut;
        getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            -amountOut.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            path
        );

        amountIn = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        require(amountInMaximum >= amountIn, "Had to withdraw too much");
    }
}
