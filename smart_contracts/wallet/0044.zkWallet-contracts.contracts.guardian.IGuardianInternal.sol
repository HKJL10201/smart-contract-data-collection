// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Partial Guardian interface needed by internal functions
 */
interface IGuardianInternal {
    enum GuardianStatus
    {
        REMOVE,    // Being removed or removed after validUntil timestamp
        ADD        // Being added or added after validSince timestamp.
    }

    struct GuardianDTO {        
        uint256 hashId;
    }

    /**
     * @notice emitted when a new Guardian is added
     * @param hashId: the hashId of the guardian
     * @param effectiveTime: the timestamp when the guardian is added
     */
    event GuardianAdded(uint256 indexed hashId, uint effectiveTime);


    /**
     * @notice emitted when a Guardian is removed
     * @param hashId: the hashId of the guardian
     * @param effectiveTime: the timestamp when the guardian is added
     */
    event GuardianRemoved (uint256 indexed hashId, uint effectiveTime);
}
