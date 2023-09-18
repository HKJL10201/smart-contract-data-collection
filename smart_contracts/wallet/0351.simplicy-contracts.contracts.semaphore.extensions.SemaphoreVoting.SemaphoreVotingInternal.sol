// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ISemaphoreVotingInternal} from "./ISemaphoreVotingInternal.sol";
import {SemaphoreVotingStorage} from "./SemaphoreVotingStorage.sol";
import {SemaphoreInternal} from "../../SemaphoreInternal.sol";

/**
 * @title SemaphoreVoting internal functions
 */
abstract contract SemaphoreVotingInternal is ISemaphoreVotingInternal, SemaphoreInternal {
    using SemaphoreVotingStorage for SemaphoreVotingStorage.Layout;
    using SemaphoreVotingStorage for SemaphoreVotingStorage.Poll;

    /**
     * @notice checks if the poll coordinator is the transaction sender
     * @param pollId: Id of the poll.
     */
    modifier onlyCoordinator(uint256 pollId) {
        require(SemaphoreVotingStorage.layout().polls[pollId].coordinator == msg.sender, "SemaphoreVoting: caller is not the poll coordinator");
        _;
    }

    /**
     * @notice See {ISemaphoreVoting-createPoll}
     */
    function _createPoll(
        uint256 pollId,
        address coordinator,
        uint8 depth
    ) internal virtual {
        SemaphoreVotingStorage.layout()._setPoolCoordinator(pollId, coordinator);
        SemaphoreVotingStorage.layout()._setPoolState(pollId, SemaphoreVotingStorage.PollState.Created);

        emit PollCreated(pollId, coordinator);
    }

    /**
     * @notice See {ISemaphoreVoting-startPoll}
     */
    function _startPoll(uint256 pollId, uint256 encryptionKey) internal virtual {
        SemaphoreVotingStorage.layout()._setPoolState(pollId, SemaphoreVotingStorage.PollState.Ongoing);

        emit PollStarted(pollId, msg.sender, encryptionKey);
    }

    /**
     * @notice See {ISemaphoreVoting-endPoll}
     */
    function _endPoll(uint256 pollId, uint256 decryptionKey) internal virtual {
        SemaphoreVotingStorage.layout()._setPoolState(pollId, SemaphoreVotingStorage.PollState.Ended);

        emit PollEnded(pollId, msg.sender, decryptionKey);
    }

    /**
     * @notice See {ISemaphoreVoting-castVote}
     */
    function _castVote(
        uint256 groupId,
        bytes32 vote,
        uint256 nullifierHash,
        uint256 pollId,
        uint256[8] calldata proof
    ) internal virtual {        
        _verifyProof(groupId, vote, nullifierHash, pollId, proof);

        emit VoteAdded(pollId, vote);
    }

    /**
     * @notice hook that is called before createPool
     */
    function _beforeCreatePool(
        uint256 pollId,
        address coordinator,
        uint8 depth
    ) internal view virtual {
        require(coordinator != address(0), "SemaphoreVoting: coordinator is the zero address");
    }

    /**
     * @notice hook that is called after createPool
     */
    function _afterCreatePool(
        uint256 pollId,
        address coordinator,
        uint8 depth
    ) internal view virtual {}
}
