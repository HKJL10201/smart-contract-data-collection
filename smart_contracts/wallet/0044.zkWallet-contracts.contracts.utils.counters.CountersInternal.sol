// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ICountersInternal} from "./ICountersInternal.sol";
import {CountersStorage} from "./CountersStorage.sol";

/**
 * @title Counters internal functions, excluding optional extensions
 */
abstract contract CountersInternal is ICountersInternal {
    using CountersStorage for CountersStorage.Layout;

    modifier counterExists(uint256 index) {
        require(index > 0, "Counters: INDEX_OUT_OF_BOUNDS");
        require(_current(index) > 0, "Counters: COUNTER_NOT_FOUND");
        _;
    }
    
    /**
     * @notice internal function: query the current value of a counter.
     * @param index: the index of the counter.
     */
    function _current(uint256 index) internal view returns (uint256) {
        return CountersStorage.layout().counterIndex[index];
    }

    /**
     * @notice internal function: increment a counter by 1.
     * @param index: the index of the counter.
     */
    function _increment(uint256 index) internal {
        CountersStorage.layout().increment(index);

        emit Incremented(index, _current(index));
    }

    /**
     * @notice internal function: decrement a counter by 1.
     * @param index: the index of the counter.
     */
    function _decrement(uint256 index) internal {
        CountersStorage.layout().decrement(index);

        emit Decremented(index, _current(index));
    }

    /**
     * @notice internal function: reset a counter to 0.
     * @param index: the index of the counter.
     */
    function _reset(uint256 index) internal {
        CountersStorage.layout().reset(index);

        emit Reset(index, _current(index));
    }

    /**
     * @notice hook that is called before increment
     */
    function _beforeIncrement(uint256 index) internal view virtual  {
        require(index > 0, "Counters: INDEX_OUT_OF_BOUNDS");
    }

     /**
     * @notice hook that is called after increment
     */
    function _afterIncrement(uint256 index) internal view virtual {}

    /**
     * @notice hook that is called before decrement
     */
    function _beforeDecrement(uint256 index) internal view virtual counterExists(index) {}

    /**
     * @notice hook that is called after decrement
     */
    function _afterDecrement(uint256 index) internal view virtual {}

    /**
     * @notice hook that is called before reset
     */
    function _beforeReset(uint256 index) internal view virtual counterExists(index) {}

    /**
     * @notice hook that is called after reset
     */
    function _afterReset(uint256 index) internal view virtual {
        require( CountersStorage.layout().counterIndex[index] == 0, "Counters: COUNTERS_NOT_RESET");
    }
}
