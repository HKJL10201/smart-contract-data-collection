//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ISemaphoreVotingInternal} from "./ISemaphoreVotingInternal.sol";

/**
 * @title SemaphoreVoting interface 
 */
interface ISemaphoreVoting is ISemaphoreVotingInternal {
    /**
     * @notice creates a poll and the associated Merkle tree/group
     * @param pollId: Id of the poll.
     * @param coordinator: coordinator of the poll
     * @param depth: depth of the tree
     */
    function createPoll(
        uint256 pollId,
        address coordinator,
        uint8 depth
    ) external;


    /**
     * @notice starts a pull and publishes the key to encrypt the votes
     * @param pollId: Id of the poll.
     * @param encryptionKey: Key to encrypt poll votes
     */
    function startPoll(uint256 pollId, uint256 encryptionKey) external;

    /**
     * @notice casts an anonymous vote in a poll
     * @param vote: encrypted vote.
     * @param nullifierHash: Nullifier hash.
     * @param pollId: Id of the poll.
     * @param proof: private zk-proof parameters
     */
    function castVote(
        uint256 groupId,
        bytes32 vote,
        uint256 nullifierHash,
        uint256 pollId,
        uint256[8] calldata proof
    ) external;

    /**
     * @notice ends a pull and publishes the key to decrypt the votes
     * @param pollId: Id of the poll.
     * @param decryptionKey: Key to decrypt poll votes
     */
    function endPoll(uint256 pollId, uint256 decryptionKey) external;
}