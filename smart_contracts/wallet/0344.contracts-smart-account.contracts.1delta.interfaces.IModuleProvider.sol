// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IModuleProvider {
    enum ModuleManagement {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct ModuleConfig {
        address moduleAddress;
        ModuleManagement action;
        bytes4[] functionSelectors;
    }

    struct ModuleAddressAndPosition {
        address moduleAddress;
        uint96 functionSelectorPosition; // position in moduleFunctionSelectors.functionSelectors array
    }

    struct ModuleFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 moduleAddressPosition; // position of moduleAddress in moduleAddresses array
    }

    function selectorToModuleAndPosition(bytes4 selector) external view returns (ModuleAddressAndPosition memory);

    function moduleFunctionSelectors(address functionAddress) external view returns (ModuleFunctionSelectors memory);

    function moduleAddresses() external view returns (address[] memory);

    function supportedInterfaces(bytes4 _interface) external view returns (bool);

    function selectorToModule(bytes4 selector) external view returns (address);

    function selectorsToModules(bytes4[] memory selectors) external view returns (address[] memory moduleAddressList);

    function moduleExists(address moduleAddress) external view returns (bool);

    function validateModules(address[] memory modules) external view;
}

interface IModuleConfigurator {
    enum ModuleManagement {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct ModuleConfig {
        address moduleAddress;
        ModuleManagement action;
        bytes4[] functionSelectors;
    }

    function configureModules(ModuleConfig[] memory _moduleConfig) external;
}
