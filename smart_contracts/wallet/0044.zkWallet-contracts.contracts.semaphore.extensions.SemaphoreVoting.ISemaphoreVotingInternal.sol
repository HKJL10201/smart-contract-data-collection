//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Partial SemaphoreVoting interface needed by internal functions
 */
interface ISemaphoreVotingInternal {
    enum PollState {
        Created,
        Ongoing,
        Ended
    }

    struct Poll {
        address coordinator;
        PollState state;
    }

    /**
     * @notice emitted when a new poll is created
     * @param pollId: Id of the poll.
     * @param coordinator: coordinator of the poll
     */
    event PollCreated(uint256 pollId, address indexed coordinator);

    /**
     * @notice emitted when a poll is started
     * @param pollId: Id of the poll.
     * @param coordinator: coordinator of the poll
     * @param encryptionKey: key to encrypt the poll votes
     */
    event PollStarted(uint256 pollId, address indexed coordinator, uint256 encryptionKey);

    /**
     * @notice emitted when a user votes on a poll
     * @param pollId: Id of the poll.
     * @param vote: user encrypted vote
     */
    event VoteAdded(uint256 indexed pollId, bytes32 vote);

    /**
     * @notice emitted when a poll is ended
     * @param pollId: Id of the poll.
     * @param coordinator: coordinator of the poll
     * @param decryptionKey: key to decrypt the poll votes
     */
    event PollEnded(uint256 pollId, address indexed coordinator, uint256 decryptionKey);
}