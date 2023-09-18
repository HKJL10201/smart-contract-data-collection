// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IBackupMode {
    /**
    * @notice Returns whether backup mode is on.
    */
    function useBackup() external view returns (bool);

    /**
    * @notice Returns the time at which backup mode was turned on.
    */
    function startTime() external view returns (uint256);

    /**
    * @notice Turns on backup mode.
    * @dev Only the contract owner can call this function.
    * @dev When backup mode is on, the liquidity bonds program will stop and the protocol will switch to liquidity mining.
    * @dev Users will be able to convert their liquidity bonds to shares in StakingRewards contract of equivalent value, and regain control of their LP tokens.
    * @dev Backup mode will only be turned on if the majority of users want to exit their liquidity bond position and are unable to do so through ExecutionPrices. 
    */
    function turnOnBackupMode() external;
}