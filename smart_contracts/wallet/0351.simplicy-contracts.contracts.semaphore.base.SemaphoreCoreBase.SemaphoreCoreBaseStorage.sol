// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SemaphoreCoreBaseStorage {
    struct Layout {
        /**
         * @notice gets a nullifier hash and returns true or false.
         * It is used to prevent double-signaling.
         */
        mapping(uint256 => bool) nullifierHashes;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.SemaphoreCoreBase");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice stores the nullifier hash to prevent double-signaling
     * @param nullifierHash: Semaphore nullifier has.
     */
    function saveNullifierHash(Layout storage s, uint256 nullifierHash)
        internal
    {
        s.nullifierHashes[nullifierHash] = true;
    }
}
