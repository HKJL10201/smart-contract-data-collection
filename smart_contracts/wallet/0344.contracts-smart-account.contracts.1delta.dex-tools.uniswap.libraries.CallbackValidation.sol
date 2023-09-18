// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "../core/IUniswapV3Pool.sol";
import "./PoolAddressCalculator.sol";

/// @notice Provides validation for callbacks from Uniswap V3 Pools
library CallbackValidation {
    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view {
        require(msg.sender == PoolAddressCalculator.computeAddress(factory, tokenA, tokenB, fee));
    }
}
