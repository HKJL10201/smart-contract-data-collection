// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ICountersInternal} from "./ICountersInternal.sol";

/**
 * @title Counters interface 
 */
interface ICounters is ICountersInternal {
    /**
     * @notice  query the current value of a counter.
     * @param index: the index of the counter.
     */
    function current(uint256 index) external returns (uint256);

    /**
     * @notice increment a counter by 1.
     * @param index: the index of the counter.
     */
    function increment(uint256 index) external;

     /**
     * @notice decrement a counter by 1.
     * @param index: the index of the counter.
     */
    function decrement(uint256 index) external;

    /**
     * @notice reset a counter to 0.
     * @param index: the index of the counter.
     */
    function reset(uint256 index) external;
}
