// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

/**
 * @title MarginTrader contract
 * @notice Allows users to build large margins positions with one contract interaction
 * @author Achthar
 */
interface IMarginTrader {
    function swapCollateralExactIn(
        address _fromAsset,
        address _toAsset,
        uint256 _fromAmount,
        uint256 _protocolId
    ) external payable;

    function swapCollateralExactOut(
        address _fromAsset,
        address _toAsset,
        uint256 _toAmount,
        uint256 _protocolId
    ) external payable;

    function swapBorrowExactIn(
        address _fromAsset,
        address _toAsset,
        uint256 _fromAmount,
        uint256 _protocolId
    ) external payable;

    function swapBorrowExactOut(
        address _fromAsset,
        address _toAsset,
        uint256 _toAmount,
        uint256 _protocolId
    ) external payable;

    function openMarginPositionExactOut(
        address _collateralAsset,
        address _borrowAsset,
        address _userAsset,
        uint256 _collateralAmount,
        uint256 _maxBorrowAmount,
        uint256 _protocolId
    ) external payable;

    function openMarginPositionExactIn(
        address _collateralAsset,
        address _borrowAsset,
        address _userAsset,
        uint256 _minCollateralAmount,
        uint256 _borrowAmount,
        uint256 _protocolId
    ) external payable;

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external;
}
