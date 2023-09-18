// SPDX-License-Identifier: MIT
/**
 * Vendored on February 16, 2022 from:
 * https://github.com/mudgen/diamond-2-hardhat/blob/0cf47c8/contracts/Diamond.sol
 */
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { LibModules } from "./libraries/LibModules.sol";
import { IModuleConfig } from "./interfaces/IModuleConfig.sol";

contract BrokerProxy {

    constructor(address _contractOwner, address _moduleConfigModule) payable {
        LibModules.setContractOwner(_contractOwner);

        // Add the moduleConfig external function from the moduleConfigModule
        IModuleConfig.ModuleConfig[] memory cut = new IModuleConfig.ModuleConfig[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IModuleConfig.configureModules.selector;
        cut[0] = IModuleConfig.ModuleConfig({
            moduleAddress: _moduleConfigModule,
            action: IModuleConfig.ModuleConfigAction.Add,
            functionSelectors: functionSelectors
        });
        LibModules.configureModules(cut, address(0), "");
    }

    // Find module for function that is called and execute the
    // function if a module is found and return any value.
    fallback() external payable {
        LibModules.ModuleStorage storage ds;
        bytes32 position = LibModules.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get module from function selector
        address module = address(bytes20(ds.modules[msg.sig]));
        require(module != address(0), "Diamond: Function does not exist");
        // Execute external function from module using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the module
            let result := delegatecall(gas(), module, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {}
}
