// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {SemaphoreGroupsBase} from "./SemaphoreGroupsBase.sol";

contract SemaphoreGroupsBaseMock is SemaphoreGroupsBase, OwnableInternal {
     function _beforeCreateGroup(
        uint256 groupId,
        uint8 depth,
        uint256 zeroValue,
        address admin
    ) internal view virtual override onlyOwner {
        super._beforeCreateGroup(groupId, depth, zeroValue, admin);
    }
}