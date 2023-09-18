// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ISemaphoreGroupsInternal} from "./ISemaphoreGroupsInternal.sol";
import {SemaphoreGroupsBaseStorage} from "./SemaphoreGroupsBaseStorage.sol";
import {SNARK_SCALAR_FIELD} from "../../../utils/Constants.sol";
import {IncrementalBinaryTreeInternal} from "../../../utils/cryptography/IncrementalBinaryTree/IncrementalBinaryTreeInternal.sol";

/**
 * @title Base SemaphoreGroups internal functions, excluding optional extensions
 */
abstract contract SemaphoreGroupsBaseInternal is ISemaphoreGroupsInternal, IncrementalBinaryTreeInternal {
    using SemaphoreGroupsBaseStorage for SemaphoreGroupsBaseStorage.Layout;    

    modifier onlyGroupAdmin(uint256 groupId) {
        require(
            _getGroupAdmin(groupId) == msg.sender,
            "SemaphoreGroupsBase: SENDER_NON_GROUP_ADMIN"
        );
        _;
    }

    modifier isScalarField(uint256 scalar) {
        require(scalar < SNARK_SCALAR_FIELD, "SCALAR_OUT_OF_BOUNDS");
        _;
    }

    modifier groupExists(uint256 groupId) {
        require(_getDepth(groupId) != 0, "SemaphoreGroupsBase: GROUP_ID_NOT_EXIST");
        _;
    }

    /**
     * @notice internal query query a groupAdmin.
     * @param groupId: the groupId of the group.
     */
    function _getGroupAdmin(uint256 groupId)
        internal
        view
        virtual
        returns (address)
    {
        return SemaphoreGroupsBaseStorage.layout().groupAdmins[groupId];
    }

    /**
     * @notice internal function creates a new group by initializing the associated tree
     * @param groupId: group id of the group
     * @param depth: depth of the tree
     * @param zeroValue: zero value of the tree
     */
    function _createGroup(
        uint256 groupId,
        uint8 depth,
        uint256 zeroValue
    ) internal virtual {
        _init(groupId, depth, zeroValue);

        emit GroupCreated(groupId, depth, zeroValue);
    }

    function _setGroupAdmin(uint256 groupId, address admin) internal {
        SemaphoreGroupsBaseStorage.layout().setGroupAdmin(groupId, admin);
    }

    /**
     * @notice  internal function adds an identity commitment to an existing group
     * @param groupId: group id of the group
     * @param identityCommitment: New identity commitment
     */
    function _addMember(uint256 groupId, uint256 identityCommitment)
        internal
        virtual
    {       
        _insert(groupId, identityCommitment);

        uint256 root = _getRoot(groupId);

        emit MemberAdded(groupId, identityCommitment, root);
    }

    /**
     * @notice  internal function removes an identity commitment from an existing group. A proof of membership is
     * needed to check if the node to be deleted is part of the tree
     * @param groupId: group id of the group
     * @param identityCommitment: New identity commitment
     * @param proofSiblings: Array of the sibling nodes of the proof of membership.
     * @param proofPathIndices: Path of the proof of membership.
     */
    function _removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) internal virtual {
        _remove(groupId, identityCommitment, proofSiblings, proofPathIndices);

        uint256 root = _getRoot(groupId);

        emit MemberRemoved(groupId, identityCommitment, root);
    }

    /**
     * @notice hook that is called before createGroup
     */
    function _beforeCreateGroup(
        uint256 groupId,
        uint8 depth,
        uint256 zeroValue,
        address admin
    ) internal view virtual isScalarField(groupId) {
        require(
            _getDepth(groupId) == 0,
            "SemaphoreGroupsBase: GROUP_ID_EXISTS"
        );
        require(admin != address(0), "SemaphoreGroupsBase: ADMIN_ZERO_ADDRESS");
    }

    /**
     * @notice hook that is called after createGroup
     */
    function _afterCreateGroup(
        uint256 groupId,
        uint8 depth,
        uint256 zeroValue,
        address admin
    ) internal view virtual {}

    /**
     * @notice hook that is called before updateGroupAdmin
     */
    function _beforeUpdateGroupAdmin(
        uint256 groupId,
        address newAdmin
    ) 
        internal view virtual 
        groupExists(groupId)
        onlyGroupAdmin(groupId)
    {}

    /**
     * @notice hook that is called after updateGroupAdmin
     */
    function _afterUpdateGroupAdmin(uint256 groupId, address newAdmin) internal view virtual {}

    /**
     * @notice hook that is called before addMembers
     */
    function _beforeAddMembers(
        uint256 groupId,
        uint256[] memory identityCommitments
    ) 
        internal view virtual
        groupExists(groupId) 
        onlyGroupAdmin(groupId) {}

    /**
     * @notice hook that is called after addMembers
     */
    function _afterAddMembers(
        uint256 groupId,
        uint256[] memory identityCommitments
    ) internal view virtual {}

    /**
     * @notice hook that is called before addMember
     */
    function _beforeAddMember(
        uint256 groupId,
        uint256 identityCommitment
    ) 
        internal view virtual
        groupExists(groupId)
        onlyGroupAdmin(groupId)
    {}

     /**
     * @notice hook that is called before addMember
     */
    function _afterAddMember(
        uint256 groupId,
        uint256 identityCommitment
    ) internal view virtual {}


    /**
     * @notice hook that is called before removeMember
     */
    function _beforeRemoveMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) 
        internal view virtual 
        groupExists(groupId) 
        onlyGroupAdmin(groupId)
    {}

    /**
     * @notice hook that is called after removeMember
     */
    function _afterRemoveMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) internal view virtual {}

    /**
     * @notice hook that is called before removeMembers
     */
    function _beforeRemoveMembers(
        uint256 groupId,
        RemoveMembersDTO[] calldata members
    ) 
        internal view virtual
        groupExists(groupId) 
        onlyGroupAdmin(groupId)
    {
        require(members.length > 0, "SemaphoreGroupsBase: NO_MEMBER_TO_REMOVE");
    }

    /**
     * @notice hook that is called after removeMembers
     */
    function _afterRemoveMembers(
        uint256 groupId,
        RemoveMembersDTO[] calldata members
    ) internal view virtual groupExists(groupId) {}

}
