// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "hardhat/console.sol";
import {SafeOwnableInternal} from "@solidstate/contracts/access/ownable/SafeOwnableInternal.sol";

import {IGuardianFacet} from "../interfaces/IGuardianFacet.sol";
import {Guardian} from "../guardian/Guardian.sol";
import {GuardianStorage} from "../guardian/GuardianStorage.sol";


import {SemaphoreGroupsBaseInternal} from "../semaphore/base/SemaphoreGroupsBase/SemaphoreGroupsBaseInternal.sol";
import {SemaphoreGroupsBaseStorage} from "../semaphore/base/SemaphoreGroupsBase/SemaphoreGroupsBaseStorage.sol";

contract GuardianFacet is IGuardianFacet,  Guardian, SemaphoreGroupsBaseInternal , SafeOwnableInternal {
    /**
     * @notice return the current version of GuardianFacet
     */
    function guardianFacetVersion() public pure override returns (string memory) {
        return "0.0.1";
    }

    /**
     * @inheritdoc IGuardianFacet
     */
    function addGuardians(
        uint256 groupId,
        uint256[] memory identityCommitments,
        GuardianDTO[] calldata guardians
    ) public override onlyOwner {
        setInitialGuardians(guardians);
        
        for (uint256 i; i < identityCommitments.length; i++) {
            _addMember(groupId, identityCommitments[i]);
        }
    }
}