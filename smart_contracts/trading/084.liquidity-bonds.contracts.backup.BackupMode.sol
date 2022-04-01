// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//OpenZeppelin
import "../openzeppelin-solidity/contracts/Ownable.sol";

//Inheritance
import '../interfaces/IBackupMode.sol';

contract BackupMode is IBackupMode, Ownable {
    bool public override useBackup;
    uint256 public override startTime;

    constructor() Ownable() {
        useBackup = false;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Turns on backup mode.
    * @notice Only the contract owner can call this function.
    * @notice When backup mode is on, the liquidity bonds program will stop and the protocol will switch to liquidity mining.
    * @notice Users will be able to convert their liquidity bonds to shares in StakingRewards contract of equivalent value, and regain control of their LP tokens.
    * @notice Backup mode will only be turned on if the majority of users want to exit their liquidity bond position and are unable to do so through ExecutionPrices. 
    */
    function turnOnBackupMode() external onlyOwner {
        require(!useBackup, "Backup mode: already using backup mode.");

        useBackup = true;
        startTime = block.timestamp;

        emit TurnedOnBackupMode();
    }

    /* ========== EVENTS ========== */

    event TurnedOnBackupMode();
}