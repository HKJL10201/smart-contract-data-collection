// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// OpenZeppelin.
import "../openzeppelin-solidity/contracts/Ownable.sol";

// Inheritance.
import '../interfaces/backup/IBackupMode.sol';

contract BackupMode is IBackupMode, Ownable {

    /* ========== STATE VARIABLES ========== */

    bool public override useBackup;
    uint256 public override startTime;

    /* ========== CONSTRUCTOR ========== */

    constructor() Ownable() {
        useBackup = false;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Turns on backup mode.
    * @dev Only the contract owner can call this function.
    * @dev When backup mode is on, the liquidity bonds program will stop and the protocol will switch to liquidity mining.
    * @dev Users will be able to convert their liquidity bonds to shares in StakingRewards contract of equivalent value, and regain control of their LP tokens.
    * @dev Backup mode will only be turned on if the majority of users want to exit their liquidity bond position and are unable to do so through ExecutionPrices. 
    */
    function turnOnBackupMode() external override onlyOwner {
        require(!useBackup, "Backup mode: Already using backup mode.");

        useBackup = true;
        startTime = block.timestamp;

        emit TurnedOnBackupMode();
    }

    /* ========== EVENTS ========== */

    event TurnedOnBackupMode();
}