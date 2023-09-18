// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Achthar - 1delta.io
* A Management contract for a dimaond of which the modules are provided by an
* external contract. The proxy contains the base viewer functions but not the
* logic that handles changes to the storage (i.e. module functions and addresses)
/******************************************************************************/

import {IModuleProvider} from "../interfaces/IModuleProvider.sol";
import {ModuleManagerStorage} from "./ModuleManagerStorage.sol";

// solhint-disable max-line-length

contract OneDeltaModuleManagerProxy is ModuleManagerStorage, IModuleProvider {
    /// View functions are implemented in the proxy to avoid delegatecall

    function moduleExists(address moduleAddress) external view returns (bool) {
        return _moduleExists[moduleAddress];
    }

    // checks if the module addresses provided are valid
    function validateModules(address[] memory modules) external view {
        for (uint256 i; i < modules.length; ) {
            if (!_moduleExists[modules[i]]) revert("OneDeltaModuleManager: Invalid module");
            unchecked {
                ++i;
            }
        }
    }

    function selectorToModuleAndPosition(bytes4 selector) external view returns (ModuleAddressAndPosition memory) {
        return _selectorToModuleAndPosition[selector];
    }

    function selectorsToModules(bytes4[] memory selectors) external view returns (address[] memory moduleAddressList) {
        for (uint256 i = 0; i < selectors.length; i++) {
            moduleAddressList[i] = _selectorToModule[selectors[i]];
        }
    }

    function moduleFunctionSelectors(address functionAddress) external view returns (ModuleFunctionSelectors memory) {
        return _moduleFunctionSelectors[functionAddress];
    }

    function moduleAddresses() external view returns (address[] memory addresses) {
        addresses = _moduleAddresses;
    }

    function selectorToModule(bytes4 selector) external view returns (address) {
        return _selectorToModule[selector];
    }

    function supportedInterfaces(bytes4 _interface) external view returns (bool) {
        return _supportedInterfaces[_interface];
    }

    /**
     * @notice Emitted when pendingImplementation is changed
     */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
     * @notice Emitted when pendingImplementation is accepted, which means AccountFactory implementation is updated
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    modifier enforceIsAdmin() {
        require(msg.sender == admin, "ModuleManager: Must be admin");
        _;
    }

    constructor() {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public enforceIsAdmin {
        require(msg.sender == admin, "SET_PENDING_IMPLEMENTATION_OWNER_CHECK");

        address oldPendingImplementation = pendingImplementation;

        pendingImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);
    }

    /**
     * @notice Accepts new implementation of AccountFactory. msg.sender must be pendingImplementation
     * @dev Admin function for new implementation to accept it's role as implementation
     */
    function _acceptImplementation() public {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(msg.sender == pendingImplementation && pendingImplementation != address(0), "ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK");

        // Save current values for inclusion in log
        address oldImplementation = implementation;
        address oldPendingImplementation = pendingImplementation;

        implementation = pendingImplementation;

        pendingImplementation = address(0);

        emit NewImplementation(oldImplementation, implementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     */
    function _setPendingAdmin(address newPendingAdmin) public enforceIsAdmin {
        // Check caller = admin
        require(msg.sender == admin, "SET_PENDING_ADMIN_OWNER_CHECK");
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     */
    function _acceptAdmin() public {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require((msg.sender == pendingAdmin && msg.sender != address(0)), "ACCEPT_ADMIN_PENDING_ADMIN_CHECK");
        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function _fallback() private {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize())
            }
            default {
                return(free_mem_ptr, returndatasize())
            }
        }
    }

    /**
     * @dev fallback just executes _fallback
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev reveive executes _fallback, too
     */
    receive() external payable {
        _fallback();
    }
}
