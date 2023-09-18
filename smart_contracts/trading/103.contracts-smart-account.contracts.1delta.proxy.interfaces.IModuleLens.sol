// SPDX-License-Identifier: MIT
/**
 * Vendored on December 23, 2021 from:
 * https://github.com/mudgen/diamond-3-hardhat/blob/7feb995/contracts/interfaces/IModuleLens.sol
 */
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IModuleLens {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Module {
        address moduleAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all module addresses and their four byte function selectors.
    /// @return modules_ Module
    function modules() external view returns (Module[] memory modules_);

    /// @notice Gets all the function selectors supported by a specific module.
    /// @param _module The module address.
    /// @return moduleFunctionSelectors_
    function moduleFunctionSelectors(address _module) external view returns (bytes4[] memory moduleFunctionSelectors_);

    /// @notice Get all the module addresses used by a diamond.
    /// @return moduleAddresses_
    function moduleAddresses() external view returns (address[] memory moduleAddresses_);

    /// @notice Gets the module that supports the given selector.
    /// @dev If module is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return moduleAddress_ The module address.
    function moduleAddress(bytes4 _functionSelector) external view returns (address moduleAddress_);
}
