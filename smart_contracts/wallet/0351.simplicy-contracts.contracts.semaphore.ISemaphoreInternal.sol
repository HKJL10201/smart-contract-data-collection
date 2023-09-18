//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Partial Semaphore interface needed by internal functions
 */
interface ISemaphoreInternal {
    struct Verifier {
        address contractAddress;
        uint8 merkleTreeDepth;
    }
    
    /**
     * @notice emitted when a Semaphore proof is verified
     * @param signal: semaphore signal
     */
    event ProofVerified(uint256 indexed groupId, bytes32 signal);
}
