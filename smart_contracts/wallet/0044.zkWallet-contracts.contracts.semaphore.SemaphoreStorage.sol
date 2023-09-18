// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IVerifier} from "../interfaces/IVerifier.sol";

library SemaphoreStorage {
    struct Layout {
        mapping(uint8 => IVerifier) verifiers;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.Semaphore");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
