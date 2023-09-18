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

import { LibModules } from  "../libraries/LibModules.sol";
import { IModuleLens } from "../interfaces/IModuleLens.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

// solhint-disable max-line-length

contract LensModule is IModuleLens, IERC165 {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Module {
    //     address moduleAddress;
    //     bytes4[] functionSelectors;
    // }
    /// @notice Gets all modules and their selectors.
    /// @return modules_ Module
    function modules() external override view returns (Module[] memory modules_) {
        LibModules.ModuleStorage storage ds = LibModules.moduleStorage();
        modules_ = new Module[](ds.selectorCount);
        uint8[] memory numModuleSelectors = new uint8[](ds.selectorCount);
        uint256 numModules;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address moduleAddress_ = address(bytes20(ds.modules[selector]));
                bool continueLoop;
                for (uint256 moduleIndex; moduleIndex < numModules; moduleIndex++) {
                    if (modules_[moduleIndex].moduleAddress == moduleAddress_) {
                        modules_[moduleIndex].functionSelectors[numModuleSelectors[moduleIndex]] = selector;
                        // probably will never have more than 256 functions from one module contract
                        require(numModuleSelectors[moduleIndex] < 255);
                        numModuleSelectors[moduleIndex]++;
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continue;
                }
                modules_[numModules].moduleAddress = moduleAddress_;
                modules_[numModules].functionSelectors = new bytes4[](ds.selectorCount);
                modules_[numModules].functionSelectors[0] = selector;
                numModuleSelectors[numModules] = 1;
                numModules++;
            }
        }
        for (uint256 moduleIndex; moduleIndex < numModules; moduleIndex++) {
            uint256 numSelectors = numModuleSelectors[moduleIndex];
            bytes4[] memory selectors = modules_[moduleIndex].functionSelectors;
            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // setting the number of modules
        assembly {
            mstore(modules_, numModules)
        }
    }

    /// @notice Gets all the function selectors supported by a specific module.
    /// @param _module The module address.
    /// @return _moduleFunctionSelectors The selectors associated with a module address.
    function moduleFunctionSelectors(address _module) external override view returns (bytes4[] memory _moduleFunctionSelectors) {
        LibModules.ModuleStorage storage ds = LibModules.moduleStorage();
        uint256 numSelectors;
        _moduleFunctionSelectors = new bytes4[](ds.selectorCount);
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address module = address(bytes20(ds.modules[selector]));
                if (_module == module) {
                    _moduleFunctionSelectors[numSelectors] = selector;
                    numSelectors++;
                }
            }
        }
        // Set the number of selectors in the array
        assembly {
            mstore(_moduleFunctionSelectors, numSelectors)
        }
    }

    /// @notice Get all the module addresses used by a diamond.
    /// @return moduleAddresses_
    function moduleAddresses() external override view returns (address[] memory moduleAddresses_) {
        LibModules.ModuleStorage storage ds = LibModules.moduleStorage();
        moduleAddresses_ = new address[](ds.selectorCount);
        uint256 numModules;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address moduleAddress_ = address(bytes20(ds.modules[selector]));
                bool continueLoop;
                for (uint256 moduleIndex; moduleIndex < numModules; moduleIndex++) {
                    if (moduleAddress_ == moduleAddresses_[moduleIndex]) {
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continue;
                }
                moduleAddresses_[numModules] = moduleAddress_;
                numModules++;
            }
        }
        // Set the number of module addresses in the array
        assembly {
            mstore(moduleAddresses_, numModules)
        }
    }

    /// @notice Gets the module that supports the given selector.
    /// @dev If module is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return moduleAddress_ The module address.
    function moduleAddress(bytes4 _functionSelector) external override view returns (address moduleAddress_) {
        LibModules.ModuleStorage storage ds = LibModules.moduleStorage();
        moduleAddress_ = address(bytes20(ds.modules[_functionSelector]));
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external override view returns (bool) {
        LibModules.ModuleStorage storage ds = LibModules.moduleStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}
