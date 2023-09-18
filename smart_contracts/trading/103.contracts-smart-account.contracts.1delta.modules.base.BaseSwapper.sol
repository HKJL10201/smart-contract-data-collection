// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

/******************************************************************************\
* Author: Achthar | 1delta 
/******************************************************************************/

import {IUniswapV3Pool} from "../../dex-tools/uniswap/core/IUniswapV3Pool.sol";
import {IUniswapV2Pair} from "../../../external-protocols/uniswapV2/core/interfaces/IUniswapV2Pair.sol";
import {BytesLib} from "../../dex-tools/uniswap/libraries/BytesLib.sol";
import {TokenTransfer} from "../../libraries/TokenTransfer.sol";
import {BaseDecoder} from "./BaseDecoder.sol";

// solhint-disable max-line-length

/**
 * @title Uniswap Callback Base contract
 * @notice Contains main logic for uniswap callbacks
 */
abstract contract BaseSwapper is TokenTransfer, BaseDecoder {
    using BytesLib for bytes;

    /// @dev Mask of lower 20 bytes.
    uint256 private constant ADDRESS_MASK = 0x00ffffffffffffffffffffffffffffffffffffffff;
    /// @dev Mask of upper 20 bytes.
    uint256 private constant ADDRESS_MASK_UPPER = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    /// @dev Mask of lower 3 bytes.
    uint256 private constant UINT24_MASK = 0xffffff;

    /// @dev MIN_SQRT_RATIO + 1 from Uniswap's TickMath
    uint160 internal immutable MIN_SQRT_RATIO = 4295128740;
    /// @dev MAX_SQRT_RATIO - 1 from Uniswap's TickMath
    uint160 internal immutable MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970341;

    bytes32 private immutable UNI_V3_FF_FACTORY;
    bytes32 private constant UNI_POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    bytes32 private immutable UNI_V2_FF_FACTORY;
    bytes32 private constant CODE_HASH_UNI_V2 = 0x1a39f3b48bfeecc839ed1f8018cb533055200a40a7e19ef735744ed10ec18cb2;

    constructor(address _factoryV2, address _factoryV3) {
        // V3 factory
        UNI_V3_FF_FACTORY = bytes32((uint256(0xff) << 248) | (uint256(uint160(_factoryV3)) << 88));
        // v2 factory
        UNI_V2_FF_FACTORY = bytes32((uint256(0xff) << 248) | (uint256(uint160(_factoryV2)) << 88));
    }

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getUniswapV3Pool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (IUniswapV3Pool pool) {
        bytes32 ffFactoryAddress = UNI_V3_FF_FACTORY;
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        assembly {
            let s := mload(0x40)
            let p := s
            mstore(p, ffFactoryAddress)
            p := add(p, 21)
            // Compute the inner hash in-place
            mstore(p, token0)
            mstore(add(p, 32), token1)
            mstore(add(p, 64), and(UINT24_MASK, fee))
            mstore(p, keccak256(p, 96))
            p := add(p, 32)
            mstore(p, UNI_POOL_INIT_CODE_HASH)
            pool := and(ADDRESS_MASK, keccak256(s, 85))
        }
    }

    /// @dev gets uniswapV2 (and fork) pair addresses
    function pairAddress(address tokenA, address tokenB) internal view returns (address pair) {
        bytes32 ff_uni = UNI_V2_FF_FACTORY;
        assembly {
            switch lt(tokenA, tokenB)
            case 0 {
                mstore(0xB14, tokenA)
                mstore(0xB00, tokenB)
            }
            default {
                mstore(0xB14, tokenB)
                mstore(0xB00, tokenA)
            }
            let salt := keccak256(0xB0C, 0x28)
            mstore(0xB00, ff_uni)
            mstore(0xB15, salt)
            mstore(0xB35, CODE_HASH_UNI_V2)

            pair := and(ADDRESS_MASK, keccak256(0xB00, 0x55))
        }
    }

    /// @dev swaps exact input through UniswapV3 or UniswapV2 style exactIn
    /// only uniswapV3 executes flashSwaps
    function swapExactIn(uint256 amountIn, bytes calldata path) internal returns (uint256 amountOut) {
        while (true) {
            address tokenIn;
            address tokenOut;
            uint8 identifier;
            assembly {
                let firstWord := calldataload(path.offset)
                tokenIn := shr(96, firstWord)
                identifier := shr(64, firstWord)
                tokenOut := shr(96, calldataload(add(path.offset, 25)))
            }
            // uniswapV3 style
            if (identifier < 50) {
                uint24 fee;
                assembly {
                    fee := and(shr(72, calldataload(path.offset)), 0xffffff)
                }
                bool zeroForOne = tokenIn < tokenOut;
                (int256 amount0, int256 amount1) = getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
                    address(this),
                    zeroForOne,
                    int256(amountIn),
                    zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
                    path[:45]
                );

                amountIn = uint256(-(zeroForOne ? amount1 : amount0));
            }
            // uniswapV2 style
            else if (identifier < 100) {
                amountIn = swapUniV2ExactIn(tokenIn, tokenOut, amountIn);
            }
            // decide whether to continue or terminate
            if (path.length > 46) {
                path = path[25:];
            } else {
                amountOut = amountIn;
                break;
            }
        }
    }

    /// @dev simple exact input swap using uniswapV2 or fork
    function swapUniV2ExactIn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) private returns (uint256 buyAmount) {
        bytes32 ff_uni = UNI_V2_FF_FACTORY;
        assembly {
            let zeroForOne := lt(tokenIn, tokenOut)
            switch zeroForOne
            case 0 {
                mstore(0xB14, tokenIn)
                mstore(0xB00, tokenOut)
            }
            default {
                mstore(0xB14, tokenOut)
                mstore(0xB00, tokenIn)
            }
            let salt := keccak256(0xB0C, 0x28)
            mstore(0xB00, ff_uni)
            mstore(0xB15, salt)
            mstore(0xB35, CODE_HASH_UNI_V2)

            let pair := and(ADDRESS_MASK_UPPER, keccak256(0xB00, 0x55))

            // EXECUTE TRANSFER TO PAIR
            let ptr := mload(0x40) // free memory pointer
            // selector for transfer(address,uint256)
            mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(pair, ADDRESS_MASK_UPPER))
            mstore(add(ptr, 0x24), amountIn)

            let success := call(gas(), and(tokenIn, ADDRESS_MASK_UPPER), 0, ptr, 0x44, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success, // call itself succeeded
                or(
                    iszero(rdsize), // no return data, or
                    and(
                        iszero(lt(rdsize, 32)), // at least 32 bytes
                        eq(mload(ptr), 1) // starts with uint256(1)
                    )
                )
            )

            if iszero(success) {
                returndatacopy(ptr, 0, rdsize)
                revert(ptr, rdsize)
            }
            // TRANSFER COMPLETE

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
                let sellAmountWithFee := mul(amountIn, 997)
                buyAmount := div(mul(sellAmountWithFee, buyReserve), add(sellAmountWithFee, mul(sellReserve, 1000)))

                // selector for swap(...)
                mstore(0xB00, 0x022c0d9f00000000000000000000000000000000000000000000000000000000)

                switch zeroForOne
                case 0 {
                    mstore(0xB04, buyAmount)
                    mstore(0xB24, 0)
                }
                default {
                    mstore(0xB04, 0)
                    mstore(0xB24, buyAmount)
                }
                mstore(0xB44, address())
                mstore(0xB64, 0x80) // bytes classifier
                mstore(0xB84, 0) // bytesdata

                success := call(
                    gas(),
                    pair,
                    0x0,
                    0xB00, // input selector
                    0xA4, // input size = 164 (selector (4bytes) plus 5*32bytes)
                    0, // output = 0
                    0 // output size = 0
                )
                if iszero(success) {
                    // Forward the error
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    function getAmountInDirect(
        address pair,
        bool zeroForOne,
        uint256 buyAmount
    ) internal view returns (uint256 sellAmount) {
        assembly {
            let ptr := mload(0x40)
            // Call pair.getReserves(), store the results at `free memo`
            mstore(ptr, 0x0902f1ac00000000000000000000000000000000000000000000000000000000)
            if iszero(staticcall(gas(), pair, ptr, 0x4, ptr, 0x40)) {
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
                    sellReserve := mload(add(ptr, 0x20))
                    buyReserve := mload(ptr)
                }
                default {
                    sellReserve := mload(ptr)
                    buyReserve := mload(add(ptr, 0x20))
                }
                // Pairs are in the range (0, 2¹¹²) so this shouldn't overflow.
                // sellAmount = (reserveIn * amountOut * 1000) /
                //     ((reserveOut - amountOut) * 997) + 1;
                sellAmount := add(div(mul(mul(sellReserve, buyAmount), 1000), mul(sub(buyReserve, buyAmount), 997)), 1)
            }
        }
    }

    function flashSwapExactOut(uint256 amountOut, bytes calldata data) internal {
        address tokenIn;
        address tokenOut;
        uint8 identifier;
        assembly {
            let firstWord := calldataload(data.offset)
            tokenOut := shr(96, firstWord)
            identifier := shr(64, firstWord)
            tokenIn := shr(96, calldataload(add(data.offset, 25)))
        }

        // uniswapV3 style
        if (identifier < 50) {
            bool zeroForOne = tokenIn < tokenOut;
            uint24 fee;
            assembly {
                fee := and(shr(72, calldataload(data.offset)), 0xffffff)
            }
            getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
                msg.sender,
                zeroForOne,
                -int256(amountOut),
                zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
                data
            );
        }
        // uniswapV2 style
        else if (identifier < 100) {
            bool zeroForOne = tokenIn < tokenOut;
            // get next pool
            address pool = pairAddress(tokenIn, tokenOut);
            uint256 amountOut0;
            uint256 amountOut1;
            // amountOut0, cache
            (amountOut0, amountOut1) = zeroForOne ? (uint256(0), amountOut) : (amountOut, uint256(0));
            IUniswapV2Pair(pool).swap(amountOut0, amountOut1, address(this), data); // cannot swap to sender due to flashSwap
            _transferERC20Tokens(tokenOut, msg.sender, amountOut);
        }
    }
}