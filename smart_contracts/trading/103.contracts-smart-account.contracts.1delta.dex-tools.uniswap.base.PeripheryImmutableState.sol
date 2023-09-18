// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract PeripheryImmutableState {
    address internal immutable factory;
    address internal immutable WETH9;

    constructor(address _factory, address _WETH9) {
        factory = _factory;
        WETH9 = _WETH9;
    }
}
