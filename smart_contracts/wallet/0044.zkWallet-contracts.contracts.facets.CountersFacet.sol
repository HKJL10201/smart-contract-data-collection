// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {SafeOwnableInternal} from "@solidstate/contracts/access/ownable/SafeOwnableInternal.sol";

import {Counters} from "../utils/counters/Counters.sol";

/**
 * @title Counters Mock 
 */
contract CountersFacet is Counters, SafeOwnableInternal {
     /**
     * @notice return the current version of CountersFacet
     */
    function countersVersion() public pure returns (string memory) {
        return "0.0.1";
    }
    function _beforeIncrement(uint256 index) internal view virtual override onlyOwner {
        super._beforeIncrement(index);
    }

   function _beforeDecrement(uint256 index) internal view virtual override onlyOwner {
        super._beforeDecrement(index);
   }

   function _beforeReset(uint256 index) internal view virtual override onlyOwner {
        super._beforeReset(index);
   }
}
