// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Achthar - 1delta.io
* A Management contract for a dimaond of which the modules are provided by an
* external contract.
/******************************************************************************/

import {IModuleProvider} from "../interfaces/IModuleProvider.sol";

// solhint-disable max-line-length

contract BaseStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;

    /**
     * @notice Active logic of contract
     */
    address public implementation;

    /**
     * @notice Pending logic of contract
     */
    address public pendingImplementation;
}

abstract contract ModuleManagerStorage is BaseStorage {
    event Upgrade(IModuleProvider.ModuleConfig[] _moduleConfig);
    // maps function selector to the module address and
    // the position of the selector in the _moduleFunctionSelectors.selectors array
    mapping(bytes4 => IModuleProvider.ModuleAddressAndPosition) internal _selectorToModuleAndPosition;
    // maps selector to module
    mapping(bytes4 => address) internal _selectorToModule;
    // maps module addresses to function selectors
    mapping(address => IModuleProvider.ModuleFunctionSelectors) internal _moduleFunctionSelectors;
    // module addresses
    address[] internal _moduleAddresses;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) internal _supportedInterfaces;
    // Used to query if a module exits
    mapping(address => bool) internal _moduleExists;
}