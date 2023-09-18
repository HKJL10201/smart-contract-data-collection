// SPDX-License-Identifier: MIT
/**
 * Vendored on February 16, 2022 from:
 * https://github.com/mudgen/diamond-2-hardhat/blob/0cf47c8/contracts/Diamond.sol
 */
pragma solidity ^0.8.0;

import { LibModules } from "../libraries/LibModules.sol";
import { IERC173 } from "../interfaces/IERC173.sol";

contract OwnershipModule is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibModules.enforceIsContractOwner();
        LibModules.setContractOwner(_newOwner);
    }

    function owner() external override view returns (address owner_) {
        owner_ = LibModules.contractOwner();
    }
}
