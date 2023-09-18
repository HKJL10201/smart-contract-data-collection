// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IGuardianInternal} from "./IGuardianInternal.sol";
import {GuardianStorage} from "./GuardianStorage.sol";

/**
 * @title Guardian interface 
 */
interface IGuardian is IGuardianInternal {
    /**
     * @notice query a guardian.
     * @param hashId: the hashId of the guardian.
     */
    function getGuardian(uint256 hashId) external returns (GuardianStorage.Guardian memory);

    /**
     * @notice query all guardians from the storage
     * @param includePendingAddition: whether to include pending addition guardians.
     */
    function getGuardians(bool includePendingAddition) external view returns (GuardianStorage.Guardian[] memory);

    /**
     * @notice query the length of the active guardians
     * @param includePendingAddition: whether to include pending addition guardians
     */
    function numGuardians(bool includePendingAddition) external view returns (uint256);

    
    /**
     * @notice check if the guardians are majority.
     * @param guardians: list of guardians to check.
     */
    function requireMajority(GuardianDTO[] calldata guardians) external view;

    /**
     * @notice set multiple guardians to the group.
     * @param guardians: guardians to be added.
     *
     * Emits multiple {GuardianAdded} event.
     */
     function setInitialGuardians(uint256[] memory guardians) external;

    /**
     * @notice add a new guardian to the group.
     * @param hashId: the hashId of the guardian.
     * @return returns a boolean value indicating whether the operation succeeded. 
     *
     * Emits a {GuardianAdded} event.
     */
     function addGuardian(uint256 hashId) external returns(bool);

    /**
     * @notice remove guardian from the group.
     * @param hashId: the hashId of the guardian.
     * @return returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {GuardianRemoved} event.
     */
     function removeGuardian(uint256 hashId) external returns(bool);

    /**
     * @notice remove multiple guardians from the group.
     * @param guardians: guardians to be removed.
     *
     * Emits multiple {GuardianRemoved} event.
     */
     function removeGuardians(uint256[] memory guardians) external;


    /**
     * @notice remove all pending guardians from the group.
     *
     * Emits multiple {GuardianRemoved} event.
     */
     function cancelPendingGuardians(
    ) external;
}
