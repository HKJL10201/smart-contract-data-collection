// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../LiquidityBond.sol";

contract TestLiquidityBond is LiquidityBond {
    constructor(address _rewardsToken, address _collateralTokenAddress, address _lpPair, address _priceAggregatorAddress, address _routerAddress, address _ubeswapRouterAddress, address _xTGEN)
        LiquidityBond(_rewardsToken, _collateralTokenAddress, _lpPair, _priceAggregatorAddress, _routerAddress, _ubeswapRouterAddress, _xTGEN)
    {
    }

    function calculateBonusAmount(uint256 _amountOfCollateral) external view returns (uint256) {
        return _calculateBonusAmount(_amountOfCollateral);
    }

    function addLiquidity(uint256 _amountOfCollateral) external {
        _addLiquidity(_amountOfCollateral);
    }

    function setStartTime(uint256 _startTime) external {
        startTime = _startTime;
    }

    function setStakedAmount(uint256 _index, uint256 _stakedAmount) external {
        stakedAmounts[_index] = _stakedAmount;
    }

    function testMint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function setTotalStakedAmount(uint256 _stakedAmount) external {
        totalStakedAmount = _stakedAmount;
    }
}