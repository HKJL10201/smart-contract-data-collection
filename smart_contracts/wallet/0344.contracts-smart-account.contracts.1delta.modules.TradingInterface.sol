// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.21;

// solhint-disable max-line-length

import {IDataProvider} from "../interfaces/IDataProvider.sol";
import {IUniswapV2Pair} from "../../external-protocols/uniswapV2/core/interfaces/IUniswapV2Pair.sol";
import {TokenTransfer} from "../libraries/TokenTransfer.sol";
import {BytesLib} from "../libraries/BytesLib.sol";
import {WithStorage} from "../libraries/LibStorage.sol";
import {LendingInteractions} from "../libraries/LendingInteractions.sol";
import {IUniswapV3Pool} from "../dex-tools/uniswap/core/IUniswapV3Pool.sol";
import {BaseSwapper} from "./base/BaseSwapper.sol";

contract TradingInterface is WithStorage, BaseSwapper, LendingInteractions {
    using BytesLib for bytes;
    error Slippage();

    uint256 private constant DEFAULT_AMOUNT_CACHED = type(uint256).max;

    constructor(
        address _uniFactory,
        address _uniFactoryV3,
        address _nativeWrapper,
        address _cNative
    ) LendingInteractions(_cNative, _nativeWrapper) BaseSwapper(_uniFactory, _uniFactoryV3) {}

    function getAmountOutDirect(
        address pair,
        bool zeroForOne,
        uint256 sellAmount
    ) private view returns (uint256 buyAmount) {
        assembly {
            // Call pair.getReserves(), store the results at `0xC00`
            mstore(0xB00, 0x0902f1ac00000000000000000000000000000000000000000000000000000000)
            if iszero(staticcall(gas(), pair, 0xB00, 0x4, 0xC00, 0x40)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
            // Revert if the pair contract does not return at least two words.
            if lt(returndatasize(), 0x40) {
                revert(0, 0)
            }

            // Compute the buy amount based on the pair reserves.
            {
                let sellReserve
                let buyReserve
                switch iszero(zeroForOne)
                case 0 {
                    // Transpose if pair order is different.
                    sellReserve := mload(0xC00)
                    buyReserve := mload(0xC20)
                }
                default {
                    sellReserve := mload(0xC20)
                    buyReserve := mload(0xC00)
                }
                // Pairs are in the range (0, 2¹¹²) so this shouldn't overflow.
                // buyAmount = (pairSellAmount * 997 * buyReserve) /
                //     (pairSellAmount * 997 + sellReserve * 1000);
                let sellAmountWithFee := mul(sellAmount, 997)
                buyAmount := div(mul(sellAmountWithFee, buyReserve), add(sellAmountWithFee, mul(sellReserve, 1000)))
            }
        }
    }

    // increase the margin position - borrow (tokenIn) and sell it against collateral (tokenOut)
    // the user provides the debt amount as input
    function swapExactIn(
        uint256 amountIn,
        uint256 amountOutMinimum,
        bytes memory path
    ) external returns (uint256 amountOut) {
        address tokenIn;
        address tokenOut;
        bool zeroForOne;
        uint8 identifier;
        assembly {
            tokenIn := div(mload(add(path, 0x20)), 0x1000000000000000000000000)
            identifier := mload(add(add(path, 0x1), 23)) // identifier for poolId
            tokenOut := div(mload(add(add(path, 0x20), 25)), 0x1000000000000000000000000)
            zeroForOne := lt(tokenIn, tokenOut)
        }

        // uniswapV2 style
        if (identifier == 0) {
            ncs().amount = amountIn;
            address pool = pairAddress(tokenIn, tokenOut);
            (uint256 amount0Out, uint256 amount1Out) = zeroForOne
                ? (uint256(0), getAmountOutDirect(pool, zeroForOne, amountIn))
                : (getAmountOutDirect(pool, zeroForOne, amountIn), uint256(0));
            IUniswapV2Pair(pool).swap(amount0Out, amount1Out, address(this), path);
        } else if (identifier == 1) {
            uint24 fee;
            assembly {
                fee := mload(add(add(path, 0x3), 20))
            }
            getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
                address(this),
                zeroForOne,
                int256(amountIn),
                zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
                path
            );
        }
        amountOut = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        if (amountOutMinimum > amountOut) revert Slippage();
    }

    // increase the margin position - borrow (tokenIn) and sell it against collateral (tokenOut)
    // the user provides the debt amount as input
    function swapExactOut(
        uint256 amountOut,
        uint256 amountInMaximum,
        bytes memory path
    ) external returns (uint256 amountIn) {
        address tokenIn;
        address tokenOut;
        bool zeroForOne;
        uint8 identifier;
        assembly {
            tokenOut := div(mload(add(path, 0x20)), 0x1000000000000000000000000)
            tokenIn := div(mload(add(add(path, 0x20), 25)), 0x1000000000000000000000000)
            zeroForOne := lt(tokenIn, tokenOut)
        }
        if (identifier == 0) {
            address pool = pairAddress(tokenIn, tokenOut);
            (uint256 amount0Out, uint256 amount1Out) = zeroForOne ? (uint256(0), amountOut) : (amountOut, uint256(0));
            IUniswapV2Pair(pool).swap(amount0Out, amount1Out, address(this), path);
        } else if (identifier == 1) {
            uint24 fee;
            assembly {
                fee := mload(add(add(path, 0x3), 20))
            }
            getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
                address(this),
                zeroForOne,
                -int256(amountOut),
                zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
                path
            );
        }
        amountIn = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        if (amountInMaximum < amountIn) revert Slippage();
    }

    function cTokenPair(address underlying, address underlyingOther) internal view returns (address, address) {
        return IDataProvider(ps().dataProvider).cTokenPair(underlying, underlyingOther);
    }

    function cTokenAddress(address underlying) internal view returns (address) {
        return IDataProvider(ps().dataProvider).cTokenAddress(underlying);
    }
}
