// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

import '../../core/interfaces/IAlgebraPool.sol';

import '../interfaces/ITickLens.sol';

/// @title Tick Lens contract
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
contract TickLens is ITickLens {
    /// @inheritdoc ITickLens
    function getPopulatedTicksInWord(
        address pool,
        int16 tickTableIndex
    ) public view override returns (PopulatedTick[] memory populatedTicks) {
        // fetch bitmap
        uint256 bitmap = IAlgebraPool(pool).tickTable(tickTableIndex);
        unchecked {
            // calculate the number of populated ticks
            uint256 numberOfPopulatedTicks;
            for (uint256 i = 0; i < 256; i++) {
                if (bitmap & (1 << i) > 0) numberOfPopulatedTicks++;
            }

            // fetch populated tick data
            populatedTicks = new PopulatedTick[](numberOfPopulatedTicks);
            for (uint256 i = 0; i < 256; i++) {
                if (bitmap & (1 << i) > 0) {
                    int24 populatedTick = ((int24(tickTableIndex) << 8) + int24(uint24(i)));
                    (uint128 liquidityGross, int128 liquidityNet, , , , , , , ) = IAlgebraPool(pool).ticks(
                        populatedTick
                    );
                    populatedTicks[--numberOfPopulatedTicks] = PopulatedTick({
                        tick: populatedTick,
                        liquidityNet: liquidityNet,
                        liquidityGross: liquidityGross
                    });
                }
            }
        }
    }
}
