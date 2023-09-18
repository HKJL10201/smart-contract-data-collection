// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {SafeOwnableInternal} from "@solidstate/contracts/access/ownable/SafeOwnableInternal.sol";
import {Recovery} from "../recovery/Recovery.sol";
import {RecoveryStorage} from "../recovery/RecoveryStorage.sol";

contract RecoveryFacet is Recovery, SafeOwnableInternal {
    using RecoveryStorage for RecoveryStorage.Layout;

    /**
     * @notice return the current version of RecoveryFacet
     */
    function recoveryFacetVersion() public pure returns (string memory) {
        return "0.0.1";
    }

    function _beforeResetRecovery() internal view virtual override onlyOwner {}

    function _duringRecovery(uint256 majority, address newOwner) internal virtual override {
        _transferOwnership(newOwner);
    }

}