// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Coungers Storage base on Diamond Standard Layout storage pattern
 */
library CountersStorage {
    struct Layout {
        // counterId -> value
        mapping(uint256 => uint256) counterIndex;       
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.Counters");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice increment a counter by 1.
     * @param index: the index of the Counter storage.
     */
    function increment(
        Layout storage s,
       uint256 index
    ) internal {
       s.counterIndex[index] += 1;
    }

    /**
     * @notice decrement a counter by 1.
     * @param index: the index of the Counter storage.
     */
    function decrement(
        Layout storage s,
       uint256 index
    ) internal {
        uint256 value =  s.counterIndex[index];
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            s.counterIndex[index] = value - 1;
        }
    }

    /**
     * @notice reset counter.
     * @param index: the index of the Counter storage.
     */
    function reset(
        Layout storage s,
       uint256 index
    ) internal {
        s.counterIndex[index] = 0;
    }
}
