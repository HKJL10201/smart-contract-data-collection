// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ISemaphoreVoting} from "./ISemaphoreVoting.sol";
import {SemaphoreVotingInternal} from "./SemaphoreVotingInternal.sol";
import {SemaphoreVotingStorage} from "./SemaphoreVotingStorage.sol";

/**
 * @title Base SemaphoreGroups functions, excluding optional extensions
 */
abstract contract SemaphoreVoting is ISemaphoreVoting, SemaphoreVotingInternal {
    using SemaphoreVotingStorage for SemaphoreVotingStorage.Layout;

    function createPoll(
        uint256 pollId,
        address coordinator,
        uint8 depth
    ) external override {
        _beforeCreatePool(pollId, coordinator, depth);

        _createPoll(pollId, coordinator, depth);

        _afterCreatePool(pollId, coordinator, depth);
    }

    function startPoll(uint256 pollId, uint256 encryptionKey)
        external
        override
    {
        _startPoll(pollId, encryptionKey);
    }

    function castVote(
        uint256 groupId,
        bytes32 vote,
        uint256 nullifierHash,
        uint256 pollId,
        uint256[8] calldata proof
    ) external override {
        _castVote(groupId, vote, nullifierHash, pollId, proof);
    }

    function endPoll(uint256 pollId, uint256 decryptionKey) external override {
        _endPoll(pollId, decryptionKey);
    }
}
