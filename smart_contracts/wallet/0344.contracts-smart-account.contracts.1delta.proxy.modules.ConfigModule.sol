// SPDX-License-Identifier: MIT
/**
 * Vendored on February 16, 2022 from:
 * https://github.com/mudgen/diamond-2-hardhat/blob/0cf47c8/contracts/Diamond.sol
 */
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IModuleConfig } from "../interfaces/IModuleConfig.sol";
import { LibModules } from "../libraries/LibModules.sol";

// solhint-disable max-line-length

contract ConfigModule is IModuleConfig {
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
    ) external override {
        LibModules.enforceIsContractOwner();
        LibModules.ModuleStorage storage ds = LibModules.moduleStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through module adjustment
        for (uint256 moduleIndex; moduleIndex < _moduleConfig.length; moduleIndex++) {
            (selectorCount, selectorSlot) = LibModules.addReplaceRemoveModuleSelectors(
                selectorCount,
                selectorSlot,
                _moduleConfig[moduleIndex].moduleAddress,
                _moduleConfig[moduleIndex].action,
                _moduleConfig[moduleIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit ModuleConfigChange(_moduleConfig, _init, _calldata);
        LibModules.initializeModuleConfig(_init, _calldata);
    }
}
