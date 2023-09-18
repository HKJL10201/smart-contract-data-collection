// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ISemaphoreGroupsInternal} from "./ISemaphoreGroupsInternal.sol";

/**
 * @title SemaphoreGroups base interface
 */
interface ISemaphoreGroupsBase is ISemaphoreGroupsInternal {
    /**
     * @notice query a groupAdmin.
     * @param groupId: the groupId of the group.
     */
    function getGroupAdmin(uint256 groupId) external view returns (address);
    
    /**
     * @notice Updates the group admin.
     * @param groupId: Id of the group.
     * @param newAdmin: New admin of the group.
     *
     * Emits a {GroupAdminUpdated} event.
     */
    function updateGroupAdmin(uint256 groupId, address newAdmin) external;
    
    /**
     * @notice ceates a new group by initializing the associated tree.
     * @param groupId: Id of the group.
     * @param depth: Depth of the tree.
     * @param zeroValue: Zero value of the tree.
     * @param admin: Admin of the group.
     *
     * Emits {GroupCreated} and {GroupAdminUpdated} events.
     */
    function createGroup(
        uint256 groupId,
        uint8 depth,
        uint256 zeroValue,
        address admin
    ) external;

    /**
     * @notice adds identity commitments to an existing group.
     * @param groupId: Id of the group.
     * @param identityCommitments: array of new identity commitments.
     *
     * TODO: hash the identityCommitments to make sure users can't see
     *       which identityCommitment belongs to the guardian
     *
     *
     * Emits multiple {MemberAdded} events.
     */
    function addMembers(uint256 groupId, uint256[] memory identityCommitments)
        external;

    /**
     * @notice add a identity commitment to an existing group.
     * @param groupId: Id of the group.
     * @param identityCommitment: the identity commitment of the member.
     *
     * TODO: hash the identityCommitment to make sure users can't see
     *       which identityCommitment belongs to the guardian
     *
     *
     * Emits a {MemberAdded} event.
     */
    function addMember(uint256 groupId, uint256 identityCommitment)
        external;

    /**
     * @notice removes an identity commitment from an existing group. A proof of membership is
     *         needed to check if the node to be deleted is part of the tree.
     * @param groupId: Id of the group.
     * @param identityCommitment: existing identity commitment to be deleted.
     * @param proofSiblings: array of the sibling nodes of the proof of membership.
     * @param proofPathIndices: path of the proof of membership.
     *
     * TODO: hash the identityCommitment to make sure users can't see
     *       which identityCommitment belongs to the guardian
      *
     * Emits a {MemberRemoved} event.
     */
    function removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external;
}
