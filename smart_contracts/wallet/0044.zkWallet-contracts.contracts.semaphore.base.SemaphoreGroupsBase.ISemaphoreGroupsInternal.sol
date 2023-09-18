// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Partial SemaphoreGroups interface needed by internal functions
 */
interface ISemaphoreGroupsInternal {
    struct RemoveMembersDTO {
        uint256 identityCommitment;
        uint256[] proofSiblings;
        uint8[] proofPathIndices;
    }

    /**
     * @notice emitted when a new group is created
     * @param groupId: group id of the group
     * @param depth: depth of the tree
     * @param zeroValue: zero value of the tree
     */
    event GroupCreated(uint256 indexed groupId, uint8 depth, uint256 zeroValue);

    /**
     * @notice emitted when an admin is assigned to a group
     * @param groupId: Id of the group
     * @param oldAdmin: Old admin of the group
     * @param newAdmin: New admin of the group
     */
    event GroupAdminUpdated(
        uint256 indexed groupId,
        address indexed oldAdmin,
        address indexed newAdmin
    );

    /**
     * @notice emitted when a new identity commitment is added
     * @param groupId: group id of the group
     * @param identityCommitment: New identity commitment
     * @param root: New root hash of the tree
     */
    event MemberAdded(
        uint256 indexed groupId,
        uint256 identityCommitment,
        uint256 root
    );

    /**
     * @notice emitted when a new identity commitment is removed
     * @param groupId: group id of the group
     * @param identityCommitment: New identity commitment
     * @param root: New root hash of the tree
     */
    event MemberRemoved(
        uint256 indexed groupId,
        uint256 identityCommitment,
        uint256 root
    );
}
