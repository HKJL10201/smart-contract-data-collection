// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Partial Counters interface needed by internal functions
 */
interface ICountersInternal {
    /**
     * @notice emitted when a counter is incremented
     * @param index: the index of the counter
     * @param newValue: the new value of the counter
     */
    event Incremented(uint256 indexed index, uint256 newValue);


    /**
     * @notice emitted when a counter is decremented
     * @param index: the index of the counter
     * @param newValue: the new value of the counter
     */
    event Decremented(uint256 indexed index, uint256 newValue);

    /**
     * @notice emitted when a counter is reseted
     * @param index: the index of the counter
     * @param newValue: the new value of the counter
     */
    event Reset(uint256 indexed index, uint256 newValue);
}
