// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface ILiquidityBond {
    // Views

    /**
     * @dev Returns whether the rewards have started.
     */
    function hasStarted() external view returns (bool);

    /**
     * @dev Returns the period index of the given timestamp.
     */
    function getPeriodIndex(uint256 _timestamp) external view returns (uint256);

    /**
     * @dev Calculates the amount of unclaimed rewards the user has available.
     * @param _account address of the user.
     * @return (uint256) amount of available unclaimed rewards.
     */
    function earned(address _account) external view returns (uint256);

    // Mutative

    /**
     * @dev Purchases liquidity bonds.
     * @notice Swaps 1/2 of collateral for TGEN and adds liquidity.
     * @notice Collateral lost to slippage/fees is returned to the user.
     * @param _amount amount of collateral to deposit.
     */
    function purchase(uint256 _amount) external;

    /**
     * @dev Claims available rewards for the user.
     */
    function getReward() external;
}