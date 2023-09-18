// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {SemaphoreVoting} from "../semaphore/extensions/SemaphoreVoting/SemaphoreVoting.sol";
import {SemaphoreVotingStorage} from "../semaphore/extensions/SemaphoreVoting/SemaphoreVotingStorage.sol";

contract SemaphoreVotingFacet is SemaphoreVoting, OwnableInternal {
    using SemaphoreVotingStorage for SemaphoreVotingStorage.Layout;

    /**
     * @notice return the current version of SemaphoreVotingFacet
     */
    function semaphoreVotingFacetVersion() public pure returns (string memory) {
        return "0.0.1";
    }

    /**
     * @notice hook that is called before createPool
     */
    function _beforeCreatePool(
        uint256 pollId,
        address coordinator,
        uint8 depth
    ) internal view virtual override onlyOwner {
        super._beforeCreatePool(pollId, coordinator, depth);
    }
}
