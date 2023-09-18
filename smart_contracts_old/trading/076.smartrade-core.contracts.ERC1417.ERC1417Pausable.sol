// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/utils/Pausable.sol";

import "./ERC1417.sol";

/**
 * @dev ERC1417 Poll Standard with pausable vote casting.
 */
abstract contract ERC1417Pausable is ERC1417, Pausable {
    /**
     * @dev See {ERC1417-_beforeVote}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeVote(uint256 proposalId) internal virtual override {
        super._beforeVote(proposalId);

        require(!paused(), "ERC1417Pausable: vote cast while paused");
    }
}
