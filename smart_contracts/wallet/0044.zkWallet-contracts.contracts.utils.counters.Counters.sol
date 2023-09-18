// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ICounters} from "./ICounters.sol";
import {CountersInternal} from "./CountersInternal.sol";
import {CountersStorage} from "./CountersStorage.sol";

/**
 * @title Counters functions 
 */
abstract contract Counters is ICounters, CountersInternal {
    /**
     * @inheritdoc ICounters
     */
    function current(uint256 index) external override returns (uint256) {
        return _current(index);
    }

    /**
     * @inheritdoc ICounters
     */
    function increment(uint256 index) external override {
        _beforeIncrement(index);

        _increment(index);

        _afterIncrement(index);
    }

    /**
     * @inheritdoc ICounters
     */
    function decrement(uint256 index) external override {
        _beforeDecrement(index);

        _decrement(index);

        _afterDecrement(index);
    }

    /**
     * @inheritdoc ICounters
     */
    function reset(uint256 index) override external {
        _beforeReset(index);

        _reset(index);

        _afterReset(index);
    }
}
