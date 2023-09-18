//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title NiftyApes interface for the admin role.
interface IOffersAdmin {
    /// @notice Updates the associated lending contract address
    function updateLendingContractAddress(address newLendingContractAddress) external;

    /// @notice Updates the associated signature lending contract address
    function updateSigLendingContractAddress(address newSigLendingContractAddress) external;

    /// @notice Pauses all interactions with the contract.
    ///         This is intended to be used as an emergency measure to avoid loosing funds.
    function pause() external;

    /// @notice Unpauses all interactions with the contract.
    function unpause() external;
}
