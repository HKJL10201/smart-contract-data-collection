//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ISemaphoreInternal} from "./ISemaphoreInternal.sol";

/**
 * @title Semaphore interface
 */
interface ISemaphore is ISemaphoreInternal {
    /**
     * @notice saves the nullifier hash to avoid double signaling and emits an event
     * if the zero-knowledge proof is valid
     * @param groupId: group id of the group
     * @param signal: semaphore signal
     * @param nullifierHash: nullifier hash
     * @param externalNullifier: external nullifier
     * @param proof: Zero-knowledge proof
     */
    function verifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external;
}
