//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ISigLendingEvents.sol";

/// @title NiftyApes interface for the admin role.
interface ISigLendingAdmin {
    /// @notice Updates the associated liquidity contract address
    function updateLendingContractAddress(address newLendingContractAddress) external;

    /// @notice Pauses all interactions with the contract.
    ///         This is intended to be used as an emergency measure to avoid loosing funds.
    function pause() external;

    /// @notice Unpauses all interactions with the contract.
    function unpause() external;
}
