// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolEvents.sol';


interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolActions,
    IUniswapV3PoolEvents
{

}
