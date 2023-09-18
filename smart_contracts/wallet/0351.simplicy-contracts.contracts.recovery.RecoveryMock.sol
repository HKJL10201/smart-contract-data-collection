// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {SafeOwnableInternal} from "@solidstate/contracts/access/ownable/SafeOwnableInternal.sol";

import {IRecovery} from "./IRecovery.sol";
import {Recovery} from "./Recovery.sol";
import {RecoveryStorage} from "./RecoveryStorage.sol";

contract RecoveryMock is IRecovery, Recovery, SafeOwnableInternal {
    using RecoveryStorage for RecoveryStorage.Layout;

    function __setStatus(uint8 status) public {
        RecoveryStorage.layout().setStatus(status);
    }

    function __setMajority(uint256 majority) public {
        RecoveryStorage.layout().setMajority(majority);
    }

    function __setNominee(address nominee) public {
        RecoveryStorage.layout().setNominee(nominee);
    }

    function __setCounter(uint8 counter) public {
        RecoveryStorage.layout().setCounter(counter);
    }

    function _duringRecovery(uint256 majority, address nominee) internal virtual override {
        _transferOwnership(nominee);
    }

    function _beforeResetRecovery() internal view virtual override onlyOwner {}

}