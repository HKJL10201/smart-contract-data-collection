//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Events emitted for changes in liquidity
interface ILiquidityEvents {
    /// @notice Emitted when a liquidity provider adds a token to the protocol.
    /// @param liquidityProvider The address of the liquidity provider adding funds
    /// @param asset The address of the token being added
    /// @param tokenAmount The amount of tokens that have been added to be protocol
    /// @param cTokenAmount The amount of compound tokens that resulted from this deposit
    event Erc20Supplied(
        address indexed liquidityProvider,
        address indexed asset,
        uint256 tokenAmount,
        uint256 cTokenAmount
    );

    /// @notice Emitted when a liquidity provider adds a compound token to the protocol.
    ///         If users have already deposited funds into compound they can directly supply compound tokens
    ///         to nifty apes
    /// @param liquidityProvider The address of the liquidity provider adding funds
    /// @param cAsset The address of the compound token being added
    /// @param cTokenAmount The amount of compound tokens that resulted from this deposit
    event CErc20Supplied(
        address indexed liquidityProvider,
        address indexed cAsset,
        uint256 cTokenAmount
    );

    /// @notice Emitted when a liquidity provider removes a token from the protocol.
    /// @param liquidityProvider The address of the liquidity provider removing funds
    /// @param asset The address of the token being removed
    /// @param tokenAmount The amount of tokens that have been removed from be protocol
    /// @param cTokenAmount The amount of compound tokens that have been removed
    event Erc20Withdrawn(
        address indexed liquidityProvider,
        address indexed asset,
        uint256 tokenAmount,
        uint256 cTokenAmount
    );

    /// @notice Emitted when a liquidity provider removes a compound token from the protocol.
    /// @param liquidityProvider The address of the liquidity provider removing funds
    /// @param cAsset The address of the compound token being removed
    /// @param cTokenAmount The amount of compound tokens being removed
    event CErc20Withdrawn(
        address indexed liquidityProvider,
        address indexed cAsset,
        uint256 cTokenAmount
    );

    /// @notice Emitted when a liquidity provider adds ethereum to the protocol
    /// @param liquidityProvider The address of the liquidity provider adding funds
    /// @param amount The amount of tokens that have been added to be protocol
    /// @param cTokenAmount The amount of compound tokens that resulted from this deposit
    event EthSupplied(address indexed liquidityProvider, uint256 amount, uint256 cTokenAmount);

    /// @notice Emitted when a liquidity provider removes ethereum from the protocol
    /// @param liquidityProvider The address of the liquidity provider removing funds
    /// @param amount The amount of ethereum that have been removed from be protocol
    /// @param cTokenAmount The amount of compound tokens that got removed
    event EthWithdrawn(address indexed liquidityProvider, uint256 amount, uint256 cTokenAmount);

    /// @notice Emitted when the owner withdraws from the protocol.
    /// @param liquidityProvider The address of the liquidity provider removing funds
    /// @param asset The address of the token being removed
    /// @param tokenAmount The amount of tokens that have been removed from be protocol
    /// @param cTokenAmount The amount of compound tokens that have been removed
    event PercentForRegen(
        address indexed liquidityProvider,
        address indexed asset,
        uint256 tokenAmount,
        uint256 cTokenAmount
    );

    /// @notice Emitted when a new asset and its corresponding cAsset are added to nifty apes allow list
    /// @param asset The asset being added to the allow list
    /// @param cAsset The address of the corresponding compound token
    event AssetToCAssetSet(address asset, address cAsset);

    /// @notice Emitted when the bps of revenue sent to the Regen Collective is changed
    /// @param oldRegenCollectiveBpsOfRevenue The old basis points denominated in parts of 10_000
    /// @param newRegenCollectiveBpsOfRevenue The new basis points denominated in parts of 10_000
    event RegenCollectiveBpsOfRevenueUpdated(
        uint16 oldRegenCollectiveBpsOfRevenue,
        uint16 newRegenCollectiveBpsOfRevenue
    );

    /// @notice Emitted when the address for the Regen Collective is changed
    /// @param newRegenCollectiveAddress The new address of the Regen Collective
    event RegenCollectiveAddressUpdated(address newRegenCollectiveAddress);

    /// @notice Emitted when the associated lending contract address is changed
    /// @param oldLendingContractAddress The old lending contract address
    /// @param newLendingContractAddress The new lending contract address
    event LiquidityXLendingContractAddressUpdated(
        address oldLendingContractAddress,
        address newLendingContractAddress
    );

    /// @notice Emitted when sanctions checks are paused
    event LiquiditySanctionsPaused();

    /// @notice Emitted when sanctions checks are unpaused
    event LiquiditySanctionsUnpaused();
}
