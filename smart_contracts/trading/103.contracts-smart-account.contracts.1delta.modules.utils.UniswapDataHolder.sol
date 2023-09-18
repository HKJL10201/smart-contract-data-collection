// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

/******************************************************************************\
* Author: Achthar
/******************************************************************************/

// solhint-disable max-line-length

/// @title Module holding uniswapV3 data
abstract contract UniswapDataHolder {
    address internal immutable v3Factory;
    address internal immutable router;

    constructor(address _factory, address _router) {
        v3Factory = _factory;
        router = _router;
    }
}
