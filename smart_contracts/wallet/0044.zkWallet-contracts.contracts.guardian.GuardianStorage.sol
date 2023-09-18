// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {SafeCast} from "@solidstate/contracts/utils/SafeCast.sol";

/**
 * @title Guardian Storage base on Diamond Standard Layout storage pattern
 */
library GuardianStorage {
    using SafeCast for uint;

    struct Guardian {
        uint256 hashId;
        uint8 status;
        uint64 timestamp;
    }
    struct Layout {
        // hashId -> guardianIdx
        mapping(uint256 => uint) guardianIndex;

        Guardian[] guardians;
        
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.Guardian");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice store an new guardian to the storage.
     * @param hashId: the hashId of the guardian.
     * @param validSince: the valid period since the guardian is added.
     * @return returns a boolean value indicating whether the operation succeeded.
     */
    function storeGuardian(
        Layout storage s,
        uint256 hashId,
        uint validSince
    ) internal returns (bool){
        uint arrayIndex = s.guardians.length;
        uint index = arrayIndex + 1;
        s.guardians.push(
            Guardian(
                hashId,
                1,
                validSince.toUint64()
            )
        );
        s.guardianIndex[hashId] = index;
        return true;
    }

    /**
     * @notice delete a guardian from the storage,
     * we are going to switch the last item in the array with the one we are replacing.
     * That way when we pop, we are removing the correct item. 
     *
     * There are two cases we need to handle:
     *  - the address we are removing is not the last address in the array
     *  - or it is the last address in the array. 
     * @param hashId: the hashId of the guardian.
     * @return returns a boolean value indicating whether the operation succeeded. 
     */
     function deleteGuardian(
        Layout storage s,
        uint256 hashId
    ) internal returns (bool) {
        uint index = s.guardianIndex[hashId];
        require(index > 0, "Guardian: GUARDIAN_NOT_EXISTS");

        uint arrayIndex = index - 1;
         require(arrayIndex >= 0, "Guardian: ARRAY_INDEX_OUT_OF_BOUNDS");

        if(arrayIndex != s.guardians.length - 1) {
            s.guardians[arrayIndex] = s.guardians[s.guardians.length - 1];
            s.guardianIndex[s.guardians[arrayIndex].hashId] = index;
        }
        s.guardians.pop();
        delete s.guardianIndex[hashId];
        return true;
    }

    /**
     * @notice delete all guardians from the storage.
     */
    function deleteAllGuardians(Layout storage s) internal {
        uint count = s.guardians.length;

        for(int i = int(count) - 1; i >= 0; i--) {
            uint256 hashId = s.guardians[uint(i)].hashId;
            deleteGuardian(s, hashId);
        }
    }
}
