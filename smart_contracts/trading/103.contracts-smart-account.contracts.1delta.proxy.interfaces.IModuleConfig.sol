// SPDX-License-Identifier: MIT
/**
 * Vendored on December 23, 2021 from:
 * https://github.com/mudgen/diamond-3-hardhat/blob/7feb995/contracts/interfaces/IModuleConfig.sol
 */
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IModuleConfig {
    enum ModuleConfigAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct ModuleConfig {
        address moduleAddress;
        ModuleConfigAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _moduleConfig Contains the module addresses and function selectors
    /// @param _init The address of the contract or module to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function configureModules(
        ModuleConfig[] calldata _moduleConfig,
        address _init,
        bytes calldata _calldata
    ) external;

    event ModuleConfigChange(ModuleConfig[] _moduleConfig, address _init, bytes _calldata);
}
