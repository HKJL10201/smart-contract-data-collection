// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

/******************************************************************************\
* Author: Achthar | 1delta 
/******************************************************************************/

import {BytesLib} from "../../dex-tools/uniswap/libraries/BytesLib.sol";
import {IUniswapV3Pool} from "../../dex-tools/uniswap/core/IUniswapV3Pool.sol";
import {PoolAddressCalculator} from "../../dex-tools/uniswap/libraries/PoolAddressCalculator.sol";

// solhint-disable max-line-length

/**
 * @title Uniswap Callback Base contract
 * @notice Contains main logic for uniswap callbacks
 */
abstract contract BaseDecoder {
    using BytesLib for bytes;

    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, 45);
    }

    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(25, path.length - 25);
    }

    function getLastToken(bytes memory data) internal pure returns (address token) {
        // fetches the last token
        uint256 len = data.length;
        assembly {
            token := div(mload(add(add(data, 0x20), sub(len, 21))), 0x1000000000000000000000000)
        }
    }

    function decodeFirstPool(bytes memory data)
        internal
        pure
        returns (
            address tokenIn,
            address tokenOut,
            uint24 fee
        )
    {
        uint8 pId;
        assembly {
            tokenIn := div(mload(add(add(data, 0x20), 0)), 0x1000000000000000000000000)
            fee := mload(add(add(data, 0x3), 20))
            pId := mload(add(add(data, 0x1), 23))
            tokenOut := div(mload(add(add(data, 0x20), 25)), 0x1000000000000000000000000)
        }
    }
}
