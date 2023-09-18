// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IStakingRewards {
    // Views

    /**
     * @dev Calculates the amount of unclaimed rewards the user has available.
     * @param account address of the user.
     * @return (uint256) amount of available unclaimed rewards.
     */
    function earned(address account) external view returns (uint256);

    /**
     * @dev Returns the total number of tokens staked in the farm.
     * @return (uint256) total supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the number of tokens the user has staked.
     * @param account address of the user.
     * @return (uint256) amount of tokens staked.
     */
    function balanceOf(address account) external view returns (uint256);

    // Mutative

    /**
     * @dev Stakes LP tokens in the farm.
     * @param amount number of tokens to stake.
     */
    function stake(uint256 amount) external;

    /**
     * @dev Withdraws LP tokens from the farm.
     * @param amount number of tokens to stake.
     */
    function withdraw(uint256 amount) external;

    /**
     * @dev Claims available rewards for the user.
     * @notice Withdraws farm's rewards from escrow contract first, then claims the user's share of those rewards.
     */
    function getReward() external;

    /**
     * @dev Withdraws all LP tokens a user has staked.
     */
    function exit() external;
}