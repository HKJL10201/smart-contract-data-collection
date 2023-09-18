//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ILiquidityAdmin.sol";
import "./ILiquidityEvents.sol";

/// @title NiftyApes interface for managing liquidity.
interface ILiquidity is ILiquidityAdmin, ILiquidityEvents {
    /// @notice Returns the address of a compound token if the compound token is in the allow list on NiftyApes, otherwise zero address.
    /// @param asset The assets address (e.g. DAI address)
    function assetToCAsset(address asset) external view returns (address);

    /// @notice Returns a maximum balance of compound tokens, if there is no limit returns zero.
    /// @param cAsset The compound token address
    function maxBalanceByCAsset(address cAsset) external view returns (uint256);

    /// @notice Returns the address for the associated lending contract
    function lendingContractAddress() external view returns (address);

    /// @notice Returns the basis points of revenue sent to the Regen Collective
    ///         denominated in basis points, parts of 10_000
    function regenCollectiveBpsOfRevenue() external view returns (uint16);

    /// @notice Returns the address for the Regen Collective
    function regenCollectiveAddress() external view returns (address);

    /// @notice Returns the address for COMP token
    function compContractAddress() external view returns (address);

    /// @notice Returns an accounts balance in compound tokens.
    /// @param account The users account address
    /// @param cAsset The compound token address
    function getCAssetBalance(address account, address cAsset) external view returns (uint256);

    /// @notice Returns the whitelisted cAsset pair to the asset
    /// @param asset The assets address (e.g. DAI address)
    function getCAsset(address asset) external view returns (address);

    /// @notice Supply a given ERC20 token.
    ///         The ERC20 token is supplied to compound and users will be earning interest
    ///         on the token.
    ///         Callers need to first approve spending of the ERC20 before calling this method
    /// @param asset The address of the ERC20 token
    /// @param amount The number of tokens to supply
    function supplyErc20(address asset, uint256 amount) external returns (uint256);

    /// @notice Supply a given compound token.
    ///         This method allows users who have already supplied tokens to compound to directly
    ///         supply their compound tokens to NiftyApes.
    /// @param cAsset The address of the compound ERC20 token
    /// @param amount The number of tokens to supply
    function supplyCErc20(address cAsset, uint256 amount) external returns (uint256);

    /// @notice Withdraw a given ERC20 token.
    ///         This method withdraws tokens from compound and unwraps the ctoken returning
    ///         the underlying asset to the user.
    /// @param asset The address of the ERC20 token
    /// @param amount The number of tokens to withdraw
    function withdrawErc20(address asset, uint256 amount) external returns (uint256);

    /// @notice Withdraw a given compound ERC20 token.
    ///         This method returns compound tokens directly to the user without returning the underlying
    /// @param cAsset The address of the compound ERC20 token
    /// @param amount The number of tokens to withdraw
    function withdrawCErc20(address cAsset, uint256 amount) external returns (uint256);

    /// @notice Supply Eth to NiftyApes.
    ///         Eth token is supplied to compound and users will be earning interest
    ///         on it.
    function supplyEth() external payable returns (uint256);

    /// @notice Withdraw Eth from NiftyApes.
    ///         This method withdraws tokens from compound and unwraps the ctoken returning
    ///         the underlying asset to the user.
    /// @param amount The amount of eth to withdraw
    function withdrawEth(uint256 amount) external returns (uint256);

    /// @notice OnlyOwner can call Withdraw COMP rewards from NiftyApes.
    function withdrawComp() external returns (uint256);

    /// @notice Function only callable by the NiftyApesLending contract
    ///         Allows lending contract to affect liquidity directly
    /// @param asset The assets address (e.g. DAI address)
    /// @param amount The amount of eth to withdraw
    /// @param to Recipient address
    function sendValue(
        address asset,
        uint256 amount,
        address to
    ) external;

    /// @notice Function only callable by the NiftyApesLending contract
    ///         Allows lending contract to affect liquidity directly
    /// @param from The address the transaction is from
    /// @param asset The assets address (e.g. DAI address)
    /// @param amount The amount of eth to withdraw
    function mintCErc20(
        address from,
        address asset,
        uint256 amount
    ) external returns (uint256);

    /// @notice Function only callable by the NiftyApesLending contract
    ///         Allows lending contract to affect liquidity directly
    function mintCEth() external payable returns (uint256);

    /// @notice Function only callable by the NiftyApesLending contract
    ///         Allows lending contract to affect liquidity directly
    /// @param asset The assets address (e.g. DAI address)
    /// @param amount The amount of eth to withdraw
    function burnCErc20(address asset, uint256 amount) external returns (uint256);

    /// @notice Function only callable by the NiftyApesLending contract
    ///         Allows lending contract to affect liquidity directly
    /// @param account The users account address
    /// @param cAsset The address of the compound ERC20 token
    /// @param cTokenAmount The amount of cToken to withdraw
    function withdrawCBalance(
        address account,
        address cAsset,
        uint256 cTokenAmount
    ) external;

    /// @notice Function only callable by the NiftyApesLending contract
    ///         Allows lending contract to affect liquidity directly
    /// @param account The users account address
    /// @param cAsset The address of the compound ERC20 token
    /// @param amount The amount of cAsset to add
    function addToCAssetBalance(
        address account,
        address cAsset,
        uint256 amount
    ) external;

    /// @notice Returns the current amount of ctokens to be minted for a given amount of an underlying asset
    /// @param asset The assets address (e.g. DAI address)
    /// @param amount The amount of asset to convert to cAsset
    function assetAmountToCAssetAmount(address asset, uint256 amount) external returns (uint256);

    /// @notice Returns the current amount of tokens to be redeemed for a given amount of cTokens
    /// @notice This function results in a slightly lower amount of the underlying asset than might be expected
    ///         Compound math truncates at the 8th decimal when going from underlying to cToken
    ///         When converting cToken to underlying this previous truncation results in a rounding down at the 8th decimal place
    ///         This only affects the NiftyApes protocol when the Owner withdraws and sends fund to the Regen Collective
    ///         And when a lender is slashed for insufficient funds they are left with a very small amount of cTokens
    ///         in their NiftyApes balance instead of a strict 0
    /// @param cAsset The compound token address
    /// @param amount The amount of asset to convert to cAsset
    function cAssetAmountToAssetAmount(address cAsset, uint256 amount) external returns (uint256);

    function initialize(address newCompContractAddress) external;
}
