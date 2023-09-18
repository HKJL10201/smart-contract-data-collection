// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IRecoveryInternal} from "./IRecoveryInternal.sol";
/**
 * @title Guardian Storage base on Diamond Standard Layout storage pattern
 */
library RecoveryStorage {
    struct Layout {
        uint8 status;
        uint256 majority;
        address nominee;
        uint8 counter;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.Recovery");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setStatus(Layout storage s, uint8 status) internal {
        s.status = status;
    }

    function setMajority(Layout storage s, uint256 majority) internal {
        s.majority = majority;
    }

    function setNominee(Layout storage s, address nominee) internal {
        s.nominee = nominee;
    }

    function setCounter(Layout storage s, uint8 counter) internal {
        s.counter = counter;
    }
}
