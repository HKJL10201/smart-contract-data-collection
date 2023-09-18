// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddressCalculator {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (address pool) {
        if (tokenA < tokenB) {
            pool = address(
                uint160(
                    uint256(
                        keccak256(abi.encodePacked(hex"ff", factory, keccak256(abi.encode(tokenA, tokenB, fee)), POOL_INIT_CODE_HASH))
                    )
                )
            );
        } else {
             pool = address(
                uint160(
                    uint256(
                        keccak256(abi.encodePacked(hex"ff", factory, keccak256(abi.encode(tokenB, tokenA, fee)), POOL_INIT_CODE_HASH))
                    )
                )
            );
        }
    }
}
