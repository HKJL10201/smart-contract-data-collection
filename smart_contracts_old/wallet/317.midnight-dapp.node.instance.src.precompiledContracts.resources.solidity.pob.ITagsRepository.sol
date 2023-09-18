pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
/// @title Smart Contract used to store PoB Tags
interface ITagsRepository {

    /// Votes for a Tag in a specified source blockchain
    /// @param chainId Source ChainId
    /// @param mmrRoot Merkle Mountain Range Root Hash to be used to claim for burned tokens
    /// @param roundHeight number of blocks the tag involve (it include blocks [0, roundHeight])
    function vote(uint8 chainId, bytes32 mmrRoot, uint256 roundHeight) external;

    /// Returns true if the given mmrRoot is a valid Tag for the chain with chainId
    /// @param chainId Source blockchain Chain Invalid
    /// @param mmrRoot Merkle Mountain Range Root to look for
    function isRecentMMRRoot(uint8 chainId, bytes32 mmrRoot) external view returns (bool);

    // Given a chain id, returns federation latest tagged block number
    /// @param chainId Source blockchain Chain Invalid
    function getRoundHeightForLastTag(uint8 chainId) external view returns (uint256);
}