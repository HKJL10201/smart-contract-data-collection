//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title NiftyApes interface for the admin role.
interface ILiquidityAdmin {
    /// @notice Allows the owner of the contract to add an asset to the allow list
    ///         All assets on NiftyApes have to have a mapping present from asset to cAsset,
    ///         The asset is a token like DAI while the cAsset is the corresponding token in compound cDAI.
    function setCAssetAddress(address asset, address cAsset) external;

    /// @notice Updates the maximum cAsset balance that the contracts will allow
    ///         This allows a guarded launch with NiftyApes limiting the amount of liquidity
    ///         in the protocol.
    function setMaxCAssetBalance(address cAsset, uint256 maxBalance) external;

    /// @notice Updates the associated lending contract address
    function updateLendingContractAddress(address newLendingContractAddress) external;

    /// @notice Updates the bps of revenue sent to the Regen Collective
    ///         Fees are denominated in basis points, parts of 10_000
    function updateRegenCollectiveBpsOfRevenue(uint16 newRegenCollectiveBpsOfRevenue) external;

    /// @notice Updates the address for the Regen Collective
    function updateRegenCollectiveAddress(address newRegenCollectiveAddress) external;

    /// @notice Pauses sanctions checks
    function pauseSanctions() external;

    /// @notice Unpauses sanctions checks
    function unpauseSanctions() external;

    /// @notice Pauses all interactions with the contract.
    ///         This is intended to be used as an emergency measure to avoid loosing funds.
    function pause() external;

    /// @notice Unpauses all interactions with the contract.
    function unpause() external;
}
