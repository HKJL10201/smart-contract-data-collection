// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Partial Recovery interface needed by internal functions
 */
interface IRecoveryInternal {
    enum RecoveryStatus {
        NONE,
        PENDING,
        ACCEPTED,
        REJECTED
    }

    /**
     * @notice emitted when a wallet is recoverd
     * @param newOwner: the address of the new owner
     */
    event Recovered(address newOwner);

    /**
     * @notice emitted when _recovery is called.
     * @param status: the new status of the recovery.
     * @param majority: the majority amount of the recovery.
     * @param nominee: the nominee address of the recovery.
     */
    event RecoveryUpdated(RecoveryStatus status, uint256 majority, address nominee, uint8 counter);
}
