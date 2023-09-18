// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IRouter {
    /**
    * @dev Swaps the given asset for TGEN.
    * @notice Need to transfer asset to Router contract before calling this function.
    * @param _asset Address of token to swap from.
    * @param _amount Number of tokens to swap.
    * @param (uint256) Amount of TGEN received.
    */
    function swapAssetForTGEN(address _asset, uint256 _amount) external returns (uint256);

    /**
    * @dev Swaps TGEN for the given asset.
    * @notice Need to transfer TGEN to Router contract before calling this function.
    * @param _asset Address of token to swap to.
    * @param _amount Number of TGEN to swap.
     * @param (uint256) Amount of asset received.
    */
    function swapTGENForAsset(address _asset, uint256 _amount) external returns (uint256);

    /**
    * @dev Adds liquidity for asset-TGEN pair.
    * @notice Need to transfer asset and TGEN to Router contract before calling this function.
    * @notice Assumes the _amountAsset and _amountTGEN has equal dollar value.
    * @notice This function is meant to be called from the LiquidityBond contract.
    * @param _asset Address of other token.
    * @param _amountAsset Amount of other token to add.
    * @param _amountTGEN Amount of TGEN to add.
    * @return (uint256) Number of LP tokens received.
    */
    function addLiquidity(address _asset, uint256 _amountAsset, uint256 _amountTGEN) external returns (uint256);

    /**
    * @dev Removes liquidity for asset-TGEN pair.
    * @notice Need to transfer LP tokens to Router contract before calling this function.
    * @notice This function is meant to be called from the LiquidityBond contract.
    * @param _asset Address of other token.
    * @param _numberOfLPTokens Number of LP tokens to remove.
    * @return (uint256, uint256) Amount of token0 received, and amount of token1 received.
    */
    function removeLiquidity(address _asset, uint256 _numberOfLPTokens) external  returns (uint256, uint256);
}