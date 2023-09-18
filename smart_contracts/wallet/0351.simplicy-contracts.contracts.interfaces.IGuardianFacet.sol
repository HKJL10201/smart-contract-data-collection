//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IGuardian} from "../guardian/IGuardian.sol";

/**
 * @title GuardianFacet interface
 */
interface IGuardianFacet is IGuardian {
    /**
     * @notice return the current version of GuardianFacet
     */
    function guardianFacetVersion() external pure returns (string memory);
    
    /**
     * @notice add guardians
     * @param groupId: the group id of the semaphore group.
     * @param identityCommitments: the identity commitments of the guardian.
     * @param guardians: guardians to add.
     *
     */
     function addGuardians(
        uint256 groupId,
        uint256[] memory identityCommitments,
        GuardianDTO[] calldata guardians
    ) external;
}
