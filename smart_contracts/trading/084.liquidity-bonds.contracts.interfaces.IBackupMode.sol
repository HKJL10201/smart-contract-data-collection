// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IBackupMode {
    /**
    * @dev Returns whether backup mode is on.
    */
    function useBackup() external view returns (bool);

    /**
    * @dev Returns the time at which backup mode was turned on.
    */
    function startTime() external view returns (uint256);

    /**
    * @dev Turns on backup mode.
    * @notice Only the contract owner can call this function.
    * @notice When backup mode is on, the liquidity bonds program will stop and the protocol will switch to liquidity mining.
    * @notice Users will be able to convert their liquidity bonds to shares in StakingRewards contract of equivalent value, and regain control of their LP tokens.
    * @notice Backup mode will only be turned on if the majority of users want to exit their liquidity bond position and are unable to do so through ExecutionPrices. 
    */
    function turnOnBackupMode() external;
}