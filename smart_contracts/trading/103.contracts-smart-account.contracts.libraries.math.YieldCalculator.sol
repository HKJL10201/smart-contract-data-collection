// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./YieldMath.sol";

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 */
library YieldCalculator {
    // All fixed point multi

    /**
     * @notice Calculates the base rate at creation from start (now) to end
     * return an 18-decimal value between 0 and 1
     */
    function rate(
        uint256 interval,
        uint256 start,
        uint256 end,
        uint256 a
    ) internal pure returns (uint256) {
        int256 int_a = int256(a);
        int256 int_t = int256(end - start);
        int256 int_interval = int256(interval);
        return uint256((int_a * _baseRate(int_a, int_t, int_interval)) / YieldMath.ONE_18 - int_a);
    }

    /**
     * @notice Calculates the rate from future times start to end at current
     * return an 18-decimal value between 0 and 1
     */
    function forwardRate(
        uint256 interval,
        uint256 current,
        uint256 start,
        uint256 end,
        uint256 a
    ) internal pure returns (uint256) {
        int256 int_a = int256(a);
        int256 int_t0 = int256(start - current);
        int256 int_t1 = int256(end - start);
        int256 int_interval = int256(interval);
        return uint256((int_a * (_baseRate(int_a, int_t1, int_interval) - _baseRate(int_a, int_t0, int_interval))) / YieldMath.ONE_18);
    }

    function _baseRate(
        int256 a,
        int256 t,
        int256 interval
    ) private pure returns (int256) {
        int256 _b = YieldMath.ln((YieldMath.ONE_18 + a) / a);
        return YieldMath.exp((_b * (t * YieldMath.ONE_18)) / interval) / YieldMath.ONE_18;
    }
}
