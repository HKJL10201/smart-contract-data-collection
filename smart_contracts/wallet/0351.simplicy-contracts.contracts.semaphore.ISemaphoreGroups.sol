// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ISemaphoreGroupsBase} from "./base/SemaphoreGroupsBase/ISemaphoreGroupsBase.sol";

/**
 * @title SemaphoreGroups interface
 */
interface ISemaphoreGroups is ISemaphoreGroupsBase {
    /**
     * @notice query the last root hash of a group
     * @param groupId: Id of the group
     * @return root hash of the group.
     */
    function getRoot(uint256 groupId) external view returns (uint256);

    /**
     * @notice query the depth of the tree of a group
     * @param groupId: Id of the group
     * @return depth of the group tree
     */
    function getDepth(uint256 groupId) external view returns (uint8);

    /**
     * @notice query the number of tree leaves of a group
     * @param groupId: Id of the group
     * @return number of tree leaves
     */
    function getNumberOfLeaves(uint256 groupId) external view returns (uint256);
}
