// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


/**
 * @title Semaphoregroups Storage base on Diamond Standard Layout storage pattern
 */
library SemaphoreGroupsBaseStorage {
    struct Layout {
        // groupId -> admin
        mapping(uint256 => address) groupAdmins;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.SemaphoreGroupsBase");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setGroupAdmin(
        Layout storage s,
        uint256 groupId,
        address admin
    ) internal {
        s.groupAdmins[groupId] = admin;
    }
}
