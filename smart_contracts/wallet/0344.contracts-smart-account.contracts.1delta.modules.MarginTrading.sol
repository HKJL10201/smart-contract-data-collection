// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

/******************************************************************************\
* Author: Achthar | 1delta 
/******************************************************************************/

import {IUniswapV2Pair} from "../../external-protocols/uniswapV2/core/interfaces/IUniswapV2Pair.sol";
import {IDataProvider} from "../interfaces/IDataProvider.sol";
import {IUniswapV3SwapCallback} from "../dex-tools/uniswap/core/IUniswapV3SwapCallback.sol";
import {TokenTransfer} from "../libraries/TokenTransfer.sol";
import {WithStorage} from "../libraries/LibStorage.sol";
import {LendingInteractions} from "../libraries/LendingInteractions.sol";
import {BaseSwapper} from "./base/BaseSwapper.sol";

// solhint-disable max-line-length

/**
 * @title Contract Module for general Margin Trading on a Compound-Style Lender
 * @notice Contains main logic for uniswap callbacks
 */
contract MarginTrading is IUniswapV3SwapCallback, WithStorage, TokenTransfer, LendingInteractions, BaseSwapper {
    error Slippage();

    uint256 private constant DEFAULT_AMOUNT_CACHED = type(uint256).max;
    address private immutable DATA_PROVIDER;

    constructor(
        address _factoryV2,
        address _factoryV3,
        address _nativeWrapper,
        address _cNative,
        address _dataProvider
    ) LendingInteractions(_cNative, _nativeWrapper) BaseSwapper(_factoryV2, _factoryV3) {
        DATA_PROVIDER = _dataProvider;
    }

    // Exact Input Swap - The path parameters determine the lending actions
    function swapExactIn(
        uint256 amountIn,
        uint256 amountOutMinimum,
        bytes calldata path
    ) external returns (uint256 amountOut) {
        address tokenIn;
        address tokenOut;
        bool zeroForOne;
        uint8 identifier;
        assembly {
            let firstWord := calldataload(path.offset)
            tokenIn := shr(96, firstWord)
            identifier := shr(64, firstWord)
            tokenOut := shr(96, calldataload(add(path.offset, 25)))
            zeroForOne := lt(tokenIn, tokenOut)
        }

        // uniswapV3 type
        if (identifier < 50) {
            uint24 fee;
            assembly {
                fee := and(shr(72, calldataload(path.offset)), 0xffffff)
            }
            getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
                address(this),
                zeroForOne,
                int256(amountIn),
                zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
                path
            );
        }
        // uniswapV2 type
        else if (identifier < 100) {
            ncs().amount = amountIn;
            tokenIn = pairAddress(tokenIn, tokenOut);
            (uint256 amount0Out, uint256 amount1Out) = zeroForOne
                ? (uint256(0), getAmountOutDirect(tokenIn, zeroForOne, amountIn))
                : (getAmountOutDirect(tokenIn, zeroForOne, amountIn), uint256(0));
            IUniswapV2Pair(tokenIn).swap(amount0Out, amount1Out, address(this), path);
        }
        amountOut = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        if (amountOutMinimum > amountOut) revert Slippage();
    }

    // Exact Output Swap - The path parameters determine the lending actions
    function swapExactOut(
        uint256 amountOut,
        uint256 amountInMaximum,
        bytes calldata path
    ) external returns (uint256 amountIn) {
        address tokenIn;
        address tokenOut;
        bool zeroForOne;
        uint8 identifier;
        assembly {
            let firstWord := calldataload(path.offset)
            tokenOut := shr(96, firstWord)
            identifier := shr(64, firstWord)
            tokenIn := shr(96, calldataload(add(path.offset, 25)))
            zeroForOne := lt(tokenIn, tokenOut)
        }
        // uniswapV3 types
        if (identifier < 50) {
            uint24 fee;
            assembly {
                fee := and(shr(72, calldataload(path.offset)), 0xffffff)
            }
            getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
                address(this),
                zeroForOne,
                -int256(amountOut),
                zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
                path
            );
        }
        // uniswapV2 types
        else if (identifier < 100) {
            tokenIn = pairAddress(tokenIn, tokenOut);
            (uint256 amount0Out, uint256 amount1Out) = zeroForOne ? (uint256(0), amountOut) : (amountOut, uint256(0));
            IUniswapV2Pair(tokenIn).swap(amount0Out, amount1Out, address(this), path);
        }
        amountIn = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        if (amountInMaximum < amountIn) revert Slippage();
    }

    // PATH IDENTIFICATION
    // [between pools if more than one]
    // 0: exact input swap
    // 1: exact output swap - flavored by the id given at the end of the path
    // [end flag]
    // 2: borrow
    // 3: withdraw
    // [start flag (>1)]
    // 6: deposit exact in
    // 7: repay exact in

    // 3: deposit exact out
    // 4: repay exact out

    // The uniswapV3 style callback
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        uint8 identifier;
        address tokenIn;
        uint24 fee;
        address tokenOut;
        uint256 tradeId;
        assembly {
            let firstWord := calldataload(_data.offset)
            tokenIn := shr(96, firstWord)
            fee := and(shr(72, firstWord), 0xffffff)
            identifier := shr(64, firstWord) // poolId
            tokenOut := shr(96, calldataload(add(_data.offset, 25)))
        }
        {
            require(msg.sender == address(getUniswapV3Pool(tokenIn, tokenOut, fee)));
        }

        assembly {
            identifier := shr(56, calldataload(_data.offset)) // identifier for  tradeType
        }
        tradeId = identifier;
        // EXACT IN BASE SWAP
        if (tradeId == 0) {
            tradeId = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);
            _transferERC20Tokens(tokenIn, msg.sender, tradeId);
        }
        // EXACT OUT - WITHDRAW or BORROW
        else if (tradeId == 1) {
            uint256 cache = _data.length;
            // fetch amount that has to be paid to the pool
            uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);
            // either initiate the next swap or pay
            if (cache > 46) {
                _data = _data[25:];
                flashSwapExactOut(amountToPay, _data);
            } else {
                // re-assign identifier
                _data = _data[(cache - 1):cache];
                // assign end flag to cache
                cache = uint8(bytes1(_data));
                tokenIn = cTokenAddress(tokenOut); // re-assign to rpevent using additional variable
                // 2 at the end is borrowing
                if (cache == 2) {
                    _borrow(tokenIn, amountToPay);
                } else {
                    // otherwise: withdraw
                    _redeemUnderlying(tokenIn, amountToPay);
                }
                _transferERC20Tokens(tokenOut, msg.sender, amountToPay);
                // cache amount
                ncs().amount = amountToPay;
            }
            return;
        }
        // MARGIN TRADING INTERACTIONS
        else {
            // exact in
            if (tradeId > 5) {
                (uint256 amountToRepayToPool, uint256 amountToSwap) = amount0Delta > 0
                    ? (uint256(amount0Delta), uint256(-amount1Delta))
                    : (uint256(amount1Delta), uint256(-amount0Delta));

                uint256 cache = _data.length;
                if (cache > 46) {
                    // we need to swap to the token that we want to supply
                    // the router returns the amount that we can finally supply to the protocol
                    _data = _data[25:];
                    amountToSwap = swapExactIn(amountToSwap, _data);
                    // supply directly
                    tokenOut = getLastToken(_data);
                    // update length
                    cache = _data.length;
                }
                // cache amount
                ncs().amount = amountToSwap;
                address cIn; // we use an additional variable to fetch both tokens in one call
                (cIn, tokenOut) = cTokenPair(tokenIn, tokenOut);
                // 6 is mint / deposit
                if (tradeId == 6) {
                    _mint(tokenOut, amountToSwap);
                } else {
                    _repayBorrow(tokenOut, amountToSwap);
                }

                // re-assign identifier
                _data = _data[(cache - 1):cache];
                // assign end flag to cache
                cache = uint8(bytes1(_data));

                // 2 is borrow
                if (cache == 2) {
                    _borrow(cIn, amountToRepayToPool);
                } else {
                    _redeemUnderlying(cIn, amountToRepayToPool);
                }
                _transferERC20Tokens(tokenIn, msg.sender, amountToRepayToPool);
            } else {
                // exact out
                (uint256 amountInLastPool, uint256 amountToSupply) = amount0Delta > 0
                    ? (uint256(amount0Delta), uint256(-amount1Delta))
                    : (uint256(amount1Delta), uint256(-amount0Delta));
                // 3 is deposit
                if (tradeId == 3) {
                    _mint(cTokenAddress(tokenIn), amountToSupply);
                } else {
                    // 4 is repay
                    _repayBorrow(cTokenAddress(tokenIn), amountToSupply);
                }
                uint256 cache = _data.length;
                // multihop if required
                if (cache > 46) {
                    _data = _data[25:];
                    flashSwapExactOut(amountInLastPool, _data);
                } else {
                    // cache amount
                    ncs().amount = amountInLastPool;
                    // fetch the flag for closing the trade
                    _data = _data[(cache - 1):cache];
                    tokenIn = cTokenAddress(tokenOut);
                    // assign end flag to cache
                    cache = uint8(bytes1(_data));
                    // borrow to pay pool
                    if (cache == 2) {
                        _borrow(tokenIn, amountInLastPool);
                    } else {
                        _redeemUnderlying(tokenIn, amountInLastPool);
                    }
                    _transferERC20Tokens(tokenOut, msg.sender, amountInLastPool);
                }
            }
            return;
        }
    }

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

    // The uniswapV2 style callback
    function uniswapV2Call(
        address,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        uint8 tradeId;
        address tokenIn;
        address tokenOut;
        bool zeroForOne;
        uint8 identifier;
        // the fee parameter in the path can be ignored for validating a V2 pool
        assembly {
            let firstWord := calldataload(data.offset)
            tokenIn := shr(96, firstWord)
            identifier := shr(64, firstWord) // uniswap fork identifier
            tradeId := shr(56, firstWord) // interaction identifier
            tokenOut := shr(96, calldataload(add(data.offset, 25)))
            zeroForOne := lt(tokenIn, tokenOut)
        }

        // calculate pool address
        address pool = pairAddress(tokenIn, tokenOut);
        {
            // validate sender
            require(msg.sender == pool);
        }

        uint256 cache = data.length;
        if (tradeId == 1) {
            // fetch amountOut
            uint256 referenceAmount = zeroForOne ? amount0 : amount1;
            // calculte amountIn
            referenceAmount = getAmountInDirect(pool, zeroForOne, referenceAmount);
            // either initiate the next swap or pay
            if (cache > 46) {
                data = data[25:];
                flashSwapExactOut(referenceAmount, data);
            } else {
                data = data[(cache - 1):cache];
                // assign end flag to cache
                cache = uint8(bytes1(data));

                tokenIn = cTokenAddress(tokenOut);
                if (cache == 2) {
                    _borrow(tokenIn, referenceAmount);
                } else {
                    _redeemUnderlying(tokenIn, referenceAmount);
                }
                _transferERC20Tokens(tokenOut, msg.sender, referenceAmount);
                // cache amount
                ncs().amount = referenceAmount;
            }
            return;
        }
        if (tradeId > 5) {
            // the swap amount is expected to be the nonzero output amount
            // since v2 does not send the input amount as parameter, we have to fetch
            // the other amount manually through the cache
            (uint256 amountToSwap, uint256 amountToBorrow) = zeroForOne ? (amount1, ncs().amount) : (amount0, ncs().amount);
            if (cache > 46) {
                // we need to swap to the token that we want to supply
                // the router returns the amount that we can finally supply to the protocol
                data = data[25:];
                amountToSwap = swapExactIn(amountToSwap, data);
                // supply directly
                tokenOut = getLastToken(data);
                // update length
                cache = data.length;
            }
            // cache amount
            ncs().amount = amountToSwap;
            (pool, tokenOut) = cTokenPair(tokenIn, tokenOut);
            // 6 is mint / deposit
            if (tradeId == 6) {
                _mint(tokenOut, amountToSwap);
            } else {
                _repayBorrow(tokenOut, amountToSwap);
            }

            // re-assign identifier
            data = data[(cache - 1):cache];
            // assign end flag to cache
            cache = uint8(bytes1(data));
            // 2 is borrow
            if (cache == 2) {
                _borrow(pool, amountToBorrow);
            } else {
                _redeemUnderlying(pool, amountToBorrow);
            }
            _transferERC20Tokens(tokenIn, msg.sender, amountToBorrow);
        } else {
            // fetch amountOut
            uint256 referenceAmount = zeroForOne ? amount0 : amount1;
            // 3 is deposit
            if (tradeId == 3) {
                _mint(cTokenAddress(tokenIn), referenceAmount);
            } else {
                // 4 is repay
                _repayBorrow(cTokenAddress(tokenIn), referenceAmount);
            }
            // calculate amountIn
            referenceAmount = getAmountInDirect(pool, zeroForOne, referenceAmount);
            // constinue swapping if more data is provided
            if (cache > 46) {
                data = data[25:];
                flashSwapExactOut(referenceAmount, data);
            } else {
                // cache amount
                ncs().amount = referenceAmount;
                tokenIn = cTokenAddress(tokenOut);
                // slice out the end flag
                data = data[(cache - 1):cache];
                // assign end flag to tradeId
                tradeId = uint8(bytes1(data));

                // borrow to pay pool
                if (tradeId == 2) {
                    _borrow(tokenIn, referenceAmount);
                } else {
                    _redeemUnderlying(tokenIn, referenceAmount);
                }
                _transferERC20Tokens(tokenOut, msg.sender, referenceAmount);
            }
        }
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        uint256 value
    ) internal {
        if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            _transferERC20Tokens(token, msg.sender, value);
        } else {
            // pull payment
            _transferERC20TokensFrom(token, payer, msg.sender, value);
        }
    }

    function cTokenPair(address underlying, address underlyingOther) internal view returns (address, address) {
        return IDataProvider(DATA_PROVIDER).cTokenPair(underlying, underlyingOther);
    }

    function cTokenAddress(address underlying) internal view returns (address) {
        return IDataProvider(DATA_PROVIDER).cTokenAddress(underlying);
    }
}
