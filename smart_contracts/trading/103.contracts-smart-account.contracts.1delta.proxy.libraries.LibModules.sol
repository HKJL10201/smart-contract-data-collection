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

// solhint-disable max-line-length

library LibModules {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct ModuleStorage {
        // maps function selectors to the modules that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address module, selector position
        mapping(bytes4 => bytes32) modules;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function moduleStorage() internal pure returns (ModuleStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        ModuleStorage storage ds = moduleStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = moduleStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == moduleStorage().contractOwner, "LibModules: Must be contract owner");
    }

    event ModuleConfig(IModuleConfig.ModuleConfig[] _moduleConfig, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of moduleConfig
    // This code is almost the same as the external moduleConfig,
    // except it is using 'Module[] memory _moduleConfig' instead of
    // 'Module[] calldata _moduleConfig'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function configureModules(
        IModuleConfig.ModuleConfig[] memory _moduleConfig,
        address _init,
        bytes memory _calldata
    ) internal {
        ModuleStorage storage ds = moduleStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through module adjustment
        for (uint256 moduleIndex; moduleIndex < _moduleConfig.length; moduleIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveModuleSelectors(
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
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit ModuleConfig(_moduleConfig, _init, _calldata);
        initializeModuleConfig(_init, _calldata);
    }

    function addReplaceRemoveModuleSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newModuleAddress,
        IModuleConfig.ModuleConfigAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        ModuleStorage storage ds = moduleStorage();
        require(_selectors.length > 0, "LibModuleConfig: No selectors in module to cut");
        if (_action == IModuleConfig.ModuleConfigAction.Add) {
            enforceHasContractCode(_newModuleAddress, "LibModuleConfig: Add module has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldModule = ds.modules[selector];
                require(address(bytes20(oldModule)) == address(0), "LibModuleConfig: Can't add function that already exists");
                // add module for selector
                ds.modules[selector] = bytes20(_newModuleAddress) | bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IModuleConfig.ModuleConfigAction.Replace) {
            enforceHasContractCode(_newModuleAddress, "LibModuleConfig: Replace module has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldModule = ds.modules[selector];
                address oldModuleAddress = address(bytes20(oldModule));
                // only useful if immutable functions exist
                require(oldModuleAddress != address(this), "LibModuleConfig: Can't replace immutable function");
                require(oldModuleAddress != _newModuleAddress, "LibModuleConfig: Can't replace function with same function");
                require(oldModuleAddress != address(0), "LibModuleConfig: Can't replace function that doesn't exist");
                // replace old module address
                ds.modules[selector] = (oldModule & CLEAR_ADDRESS_MASK) | bytes20(_newModuleAddress);
            }
        } else if (_action == IModuleConfig.ModuleConfigAction.Remove) {
            require(_newModuleAddress == address(0), "LibModuleConfig: Remove module address must be address(0)");
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldModule = ds.modules[selector];
                    require(address(bytes20(oldModule)) != address(0), "LibModuleConfig: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldModule)) != address(this), "LibModuleConfig: Can't remove immutable function");
                    // replace selector with last selector in ds.modules
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.modules[lastSelector] = (oldModule & CLEAR_ADDRESS_MASK) | bytes20(ds.modules[lastSelector]);
                    }
                    delete ds.modules[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldModule));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibModuleConfig: Incorrect ModuleConfigAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeModuleConfig(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibModuleConfig: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibModuleConfig: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibModuleConfig: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibModuleConfig: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}
