// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Partial SemaphoreCore interface needed by internal functions
 */
interface ISemaphoreCoreBaseInternal {
    /**
     * @notice emitted when a proof is verified correctly and a new nullifier hash is added.
     * @param nullifierHash: hash of external and identity nullifiers.
     */
     event NullifierHashAdded(uint256 nullifierHash);
}
