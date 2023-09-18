// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface ILiquidityBond {
    /**
     * @notice Returns whether the rewards have started.
     */
    function hasStarted() external view returns (bool);

    /**
     * @notice Returns the period index of the given timestamp.
     */
    function getPeriodIndex(uint256 _timestamp) external view returns (uint256);

    /**
     * @notice Calculates the amount of unclaimed rewards the user has available.
     * @param _account address of the user.
     * @return (uint256) amount of available unclaimed rewards.
     */
    function earned(address _account) external view returns (uint256);

    /**
     * @notice Purchases liquidity bonds.
     * @dev Swaps 1/2 of collateral for TGEN and adds liquidity.
     * @dev Collateral lost to slippage/fees is returned to the user.
     * @param _amount amount of collateral to deposit.
     */
    function purchase(uint256 _amount) external;

    /**
     * @notice Claims available rewards for the user.
     */
    function getReward() external;
}