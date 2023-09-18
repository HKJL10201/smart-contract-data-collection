// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IRecoveryInternal} from "./IRecoveryInternal.sol";

/**
 * @title Recovery interface 
 */
interface IRecovery is IRecoveryInternal {
    /**
     * @notice query the status of the recovery
     */
    function getRecoveryStatus() external view returns (RecoveryStatus);

    /**
     * @notice query the majority of the recovery
     */
    function getMajority() external view returns (uint256);

    /**
     * @notice query the nominee of the recovery
     */
    function getRecoveryNominee() external view returns (address);

    /**
     * @notice query the counter of the recovery
     */
    function getRecoveryCounter() external view returns (uint8);

    /**
     * @notice recover the wallet by setting a new owner.
     * @param groupId the group id of the semaphore groups
     * @param signal: semaphore signal
     * @param nullifierHash: nullifier hash
     * @param externalNullifier: external nullifier
     * @param proof: Zero-knowledge proof
     */
    function recover(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        address newOwner
    ) external;

    /**
     * @notice reset the recovery
     */
    function resetRecovery() external;
}
